import AppKit
import SwiftUI

struct NativeMarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var editorState: MarkdownEditorState
    let presentation: WorkspaceMode

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.string = text
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.usesFindPanel = true
        textView.allowsUndo = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.font = .systemFont(ofSize: 18, weight: .regular)
        textView.textColor = .labelColor
        textView.backgroundColor = .windowBackgroundColor
        textView.textContainerInset = NSSize(width: 56, height: 36)
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.applyPresentation(to: textView)
        editorState.updateSelection(textView.selectedRange(), in: textView.string)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = context.coordinator.textView else {
            return
        }

        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(clamp(selectedRange, maxLength: (text as NSString).length))
        }

        context.coordinator.applyPresentation(to: textView)
        context.coordinator.applyPendingRequestIfNeeded()
    }

    private func clamp(_ range: NSRange, maxLength: Int) -> NSRange {
        let location = min(range.location, maxLength)
        let length = min(range.length, max(0, maxLength - location))
        return NSRange(location: location, length: length)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeMarkdownTextView
        weak var textView: NSTextView?
        private var lastHandledRequestID: UUID?
        private var isApplyingPresentation = false
        private var lastPresentedText = ""
        private var lastPresentedMode: WorkspaceMode?

        init(parent: NativeMarkdownTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else {
                return
            }

            let updatedText = textView.string
            parent.text = updatedText
            applyPresentation(to: textView, force: true)
            parent.editorState.updateSelection(textView.selectedRange(), in: updatedText)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView else {
                return
            }

            parent.editorState.updateSelection(textView.selectedRange(), in: textView.string)
        }

        func applyPendingRequestIfNeeded() {
            guard let request = parent.editorState.pendingRequest,
                  request.id != lastHandledRequestID,
                  let textView
            else {
                return
            }

            lastHandledRequestID = request.id
            apply(request.command, to: textView)
            parent.editorState.markHandled(request)
        }

        func applyPresentation(to textView: NSTextView, force: Bool = false) {
            guard !isApplyingPresentation else {
                return
            }

            let text = textView.string
            let mode = parent.presentation

            guard force || lastPresentedText != text || lastPresentedMode != mode else {
                return
            }

            isApplyingPresentation = true
            let selectedRange = textView.selectedRange()
            MarkdownTextStyler.apply(to: textView, text: text, presentation: mode)

            if textView.selectedRange() != selectedRange {
                textView.setSelectedRange(selectedRange)
            }

            lastPresentedText = text
            lastPresentedMode = mode
            isApplyingPresentation = false
        }

        private func apply(_ command: EditorCommand, to textView: NSTextView) {
            switch command {
            case .bold:
                wrapSelection(in: textView, prefix: "**", suffix: "**", placeholder: "bold")
            case .italic:
                wrapSelection(in: textView, prefix: "*", suffix: "*", placeholder: "italic")
            case .code:
                wrapSelection(in: textView, prefix: "`", suffix: "`", placeholder: "code")
            case .quote:
                prefixCurrentLines(in: textView, prefix: "> ")
            case .checklist:
                prefixCurrentLines(in: textView, prefix: "- [ ] ")
            case .heading(let level):
                prefixCurrentLines(in: textView, prefix: String(repeating: "#", count: level) + " ")
            case .link:
                insertLinkTemplate(in: textView)
            case .insertTable(let columns, let rows):
                insertTable(in: textView, columns: columns, rows: rows)
            case .jumpToLine(let lineNumber):
                jump(toLine: lineNumber, in: textView)
            }
        }

        private func wrapSelection(
            in textView: NSTextView,
            prefix: String,
            suffix: String,
            placeholder: String
        ) {
            let range = textView.selectedRange()
            let nsString = textView.string as NSString
            let selectedText = range.length > 0 ? nsString.substring(with: range) : placeholder
            let replacement = prefix + selectedText + suffix
            let selectionStart = range.location + (prefix as NSString).length
            let selectionLength = (selectedText as NSString).length

            replaceText(in: textView, range: range, with: replacement)
            textView.setSelectedRange(NSRange(location: selectionStart, length: selectionLength))
            textView.scrollRangeToVisible(textView.selectedRange())
        }

        private func prefixCurrentLines(in textView: NSTextView, prefix: String) {
            let nsString = textView.string as NSString
            let selectedRange = textView.selectedRange()
            let lineRange = nsString.lineRange(for: selectedRange)
            let block = nsString.substring(with: lineRange)
            let hasTrailingNewline = block.hasSuffix("\n")
            var lines = block.components(separatedBy: "\n")

            if hasTrailingNewline {
                lines.removeLast()
            }

            let replacement = lines
                .map { line in
                    line.isEmpty ? prefix : prefix + line
                }
                .joined(separator: "\n") + (hasTrailingNewline ? "\n" : "")

            replaceText(in: textView, range: lineRange, with: replacement)
            textView.setSelectedRange(NSRange(location: lineRange.location, length: (replacement as NSString).length))
            textView.scrollRangeToVisible(textView.selectedRange())
        }

        private func insertLinkTemplate(in textView: NSTextView) {
            let range = textView.selectedRange()
            let nsString = textView.string as NSString
            let label = range.length > 0 ? nsString.substring(with: range) : "link text"
            let url = "https://example.com"
            let replacement = "[\(label)](\(url))"
            let urlStart = range.location + (label as NSString).length + 3

            replaceText(in: textView, range: range, with: replacement)
            textView.setSelectedRange(NSRange(location: urlStart, length: (url as NSString).length))
            textView.scrollRangeToVisible(textView.selectedRange())
        }

        private func insertTable(in textView: NSTextView, columns: Int, rows: Int) {
            let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
            let insertion = MarkdownTableEditor.insertTable(
                in: textView.string,
                selectedRange: textView.selectedRange(),
                columns: columns,
                rows: rows
            )

            replaceText(in: textView, range: fullRange, with: insertion.text)
            textView.setSelectedRange(insertion.selectionRange)
            textView.scrollRangeToVisible(textView.selectedRange())
        }

        private func jump(toLine targetLine: Int, in textView: NSTextView) {
            let nsString = textView.string as NSString
            var currentLine = 1
            var location = 0

            while currentLine < targetLine && location < nsString.length {
                let lineRange = nsString.lineRange(for: NSRange(location: location, length: 0))
                location = NSMaxRange(lineRange)
                currentLine += 1
            }

            let clampedLocation = min(location, nsString.length)
            let targetRange = nsString.lineRange(for: NSRange(location: clampedLocation, length: 0))
            let visibleLength = max(0, targetRange.length - (targetRange.location + targetRange.length <= nsString.length ? 1 : 0))
            textView.window?.makeFirstResponder(textView)
            textView.setSelectedRange(NSRange(location: targetRange.location, length: visibleLength))
            textView.scrollRangeToVisible(targetRange)
        }

        private func replaceText(in textView: NSTextView, range: NSRange, with replacement: String) {
            textView.textStorage?.beginEditing()
            textView.textStorage?.replaceCharacters(in: range, with: replacement)
            textView.textStorage?.endEditing()
            textView.didChangeText()
            AppLogger.editor.debug("Applied markdown editing command to range \(range.location, privacy: .public):\(range.length, privacy: .public)")
        }
    }
}
