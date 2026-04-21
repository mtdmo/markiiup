import AppKit
import Foundation

@MainActor
enum MarkdownTextStyler {
    private struct LineSlice {
        let text: String
        let range: NSRange
    }

    private struct StyledTableBlock {
        let lines: [LineSlice]
        let nextIndex: Int
    }

    private static let bodyFont = NSFont.systemFont(ofSize: 18, weight: .regular)
    private static let sourceFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    private static let headingSizes: [CGFloat] = [30, 24, 20, 18, 17, 16]

    private static let headingRegex = try! NSRegularExpression(pattern: "^(\\s*)(#{1,6})(\\s+)(.*)$")
    private static let blockquoteRegex = try! NSRegularExpression(pattern: "^(\\s*>\\s?)(.*)$")
    private static let checklistRegex = try! NSRegularExpression(pattern: "^(\\s*[-*]\\s\\[(?: |x|X)\\]\\s)(.*)$")
    private static let listRegex = try! NSRegularExpression(pattern: "^(\\s*(?:[-*]|\\d+[.])\\s)(.*)$")

    private static let boldRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*\\*([^*\\n]+)\\*\\*(?!\\*)")
    private static let italicRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*([^*\\n]+)\\*(?!\\*)")
    private static let inlineCodeRegex = try! NSRegularExpression(pattern: "`([^`\\n]+)`")
    private static let markdownLinkRegex = try! NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)")
    private static let wikiLinkRegex = try! NSRegularExpression(pattern: "\\[\\[([^\\]]+)\\]\\]")
    private static let tagRegex = try! NSRegularExpression(pattern: "(?<!\\w)#([A-Za-z0-9_-]+)\\b")

    static func apply(
        to textView: NSTextView,
        text: String,
        presentation: WorkspaceMode,
        editedRange: NSRange? = nil,
        forceFullLayout: Bool = false
    ) {
        switch presentation {
        case .document:
            if forceFullLayout || editedRange == nil {
                applyDocumentPresentation(to: textView, text: text)
            } else {
                applyIncrementalDocumentPresentation(to: textView, text: text, editedRange: editedRange!)
            }
        case .markdown:
            applyMarkdownPresentation(to: textView, text: text)
        }
    }

    private static func applyMarkdownPresentation(to textView: NSTextView, text: String) {
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        let storage = textView.textStorage
        storage?.beginEditing()

        if fullRange.length > 0 {
            storage?.setAttributes(markdownBaseAttributes, range: fullRange)
        }

        storage?.endEditing()

        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 16, height: 20)
        textView.typingAttributes = markdownBaseAttributes
        textView.selectedTextAttributes = selectedTextAttributes
        textView.insertionPointColor = .labelColor
    }

    private static func applyDocumentPresentation(to textView: NSTextView, text: String) {
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let storage = textView.textStorage
        storage?.beginEditing()

        if fullRange.length > 0 {
            storage?.setAttributes(documentBaseAttributes, range: fullRange)
            let protectedRanges = applyLineLevelStyles(in: text, storage: storage, scopeRange: nil)
            applyInlineStyles(in: text, storage: storage, protectedRanges: protectedRanges, searchRange: fullRange)
        }

        storage?.endEditing()
        applyDocumentViewConfiguration(to: textView)
    }

    private static func applyIncrementalDocumentPresentation(
        to textView: NSTextView,
        text: String,
        editedRange: NSRange
    ) {
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        guard fullRange.length > 0 else {
            applyDocumentViewConfiguration(to: textView)
            return
        }

        let clampedEditedRange = clamp(editedRange, maxLength: nsText.length)

        guard !shouldUseFullDocumentPass(for: clampedEditedRange, in: text) else {
            applyDocumentPresentation(to: textView, text: text)
            return
        }

        let scopedRange = expandedParagraphRange(for: clampedEditedRange, in: nsText)
        let storage = textView.textStorage
        storage?.beginEditing()
        storage?.setAttributes(documentBaseAttributes, range: scopedRange)
        let protectedRanges = applyLineLevelStyles(in: text, storage: storage, scopeRange: scopedRange)
        applyInlineStyles(in: text, storage: storage, protectedRanges: protectedRanges, searchRange: scopedRange)
        storage?.endEditing()

        applyDocumentViewConfiguration(to: textView)
    }

    private static func applyDocumentViewConfiguration(to textView: NSTextView) {
        textView.backgroundColor = NSColor.windowBackgroundColor
        textView.textContainerInset = NSSize(width: 56, height: 36)
        textView.typingAttributes = documentTypingAttributes
        textView.selectedTextAttributes = selectedTextAttributes
        textView.insertionPointColor = .labelColor
    }

    private static func applyLineLevelStyles(
        in text: String,
        storage: NSTextStorage?,
        scopeRange: NSRange?
    ) -> [NSRange] {
        var protectedRanges: [NSRange] = []
        var inFrontMatter = false
        var inCodeBlock = false
        let lines = lineSlices(in: text)
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.text.trimmingCharacters(in: .whitespaces)
            let lineIntersectsScope = scopeRange.map { NSIntersectionRange($0, line.range).length > 0 } ?? true

            if index == 0, trimmed == "---" {
                inFrontMatter = true
                if lineIntersectsScope {
                    applyAttributes(frontMatterBoundaryAttributes, to: line.range, storage: storage)
                    protectedRanges.append(line.range)
                }
                index += 1
                continue
            }

            if inFrontMatter {
                if lineIntersectsScope {
                    applyAttributes(frontMatterAttributes, to: line.range, storage: storage)
                    protectedRanges.append(line.range)
                }

                if trimmed == "---" {
                    if lineIntersectsScope {
                        applyAttributes(frontMatterBoundaryAttributes, to: line.range, storage: storage)
                    }
                    inFrontMatter = false
                }

                index += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                if lineIntersectsScope {
                    applyAttributes(codeFenceAttributes, to: line.range, storage: storage)
                    protectedRanges.append(line.range)
                }
                inCodeBlock.toggle()
                index += 1
                continue
            }

            if inCodeBlock {
                if lineIntersectsScope {
                    applyAttributes(codeBlockAttributes, to: line.range, storage: storage)
                    protectedRanges.append(line.range)
                }
                index += 1
                continue
            }

            if let tableBlock = parseTableBlock(at: index, from: lines) {
                let blockIntersectsScope = scopeRange.map { range in
                    tableBlock.lines.contains { NSIntersectionRange($0.range, range).length > 0 }
                } ?? true

                if blockIntersectsScope {
                    applyTableStyle(tableBlock, storage: storage)
                    protectedRanges.append(contentsOf: tableBlock.lines.map(\.range))
                }

                index = tableBlock.nextIndex
                continue
            }

            guard lineIntersectsScope else {
                index += 1
                continue
            }

            if applyHeadingStyle(for: line.text, lineRange: line.range, storage: storage) {
                index += 1
                continue
            }

            if applyChecklistStyle(for: line.text, lineRange: line.range, storage: storage) {
                index += 1
                continue
            }

            if applyBlockquoteStyle(for: line.text, lineRange: line.range, storage: storage) {
                index += 1
                continue
            }

            _ = applyListStyle(for: line.text, lineRange: line.range, storage: storage)
            index += 1
        }

        return protectedRanges
    }

    private static func parseTableBlock(at index: Int, from lines: [LineSlice]) -> StyledTableBlock? {
        guard index + 1 < lines.count else {
            return nil
        }

        let headerCells = parseTableCells(from: lines[index].text)
        let separatorCells = parseTableCells(from: lines[index + 1].text)

        guard headerCells.count >= 2,
              separatorCells.count == headerCells.count,
              separatorCells.allSatisfy(isSeparatorCell)
        else {
            return nil
        }

        var blockLines: [LineSlice] = [lines[index], lines[index + 1]]
        var nextIndex = index + 2

        while nextIndex < lines.count {
            let rowCells = parseTableCells(from: lines[nextIndex].text)
            guard rowCells.count >= 2 else {
                break
            }

            blockLines.append(lines[nextIndex])
            nextIndex += 1
        }

        return StyledTableBlock(lines: blockLines, nextIndex: nextIndex)
    }

    private static func applyTableStyle(_ tableBlock: StyledTableBlock, storage: NSTextStorage?) {
        let headerFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .semibold)
        let rowFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let separatorFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        for (index, line) in tableBlock.lines.enumerated() {
            let paragraphStyle = tableParagraphStyle(
                topPadding: index == 0 ? 12 : 0,
                bottomPadding: index == tableBlock.lines.count - 1 ? 12 : 0
            )

            let baseAttributes: [NSAttributedString.Key: Any]
            switch index {
            case 0:
                baseAttributes = [
                    .font: headerFont,
                    .foregroundColor: NSColor.labelColor,
                    .backgroundColor: NSColor.controlAccentColor.withAlphaComponent(0.10),
                    .paragraphStyle: paragraphStyle
                ]
            case 1:
                baseAttributes = [
                    .font: separatorFont,
                    .foregroundColor: NSColor.tertiaryLabelColor,
                    .backgroundColor: NSColor.controlAccentColor.withAlphaComponent(0.06),
                    .paragraphStyle: paragraphStyle
                ]
            default:
                baseAttributes = [
                    .font: rowFont,
                    .foregroundColor: NSColor.labelColor,
                    .backgroundColor: (index % 2 == 0
                        ? NSColor.controlBackgroundColor
                        : NSColor.controlBackgroundColor.withAlphaComponent(0.65)),
                    .paragraphStyle: paragraphStyle
                ]
            }

            applyAttributes(baseAttributes, to: line.range, storage: storage)
            applyPipeSyntaxStyle(in: line, font: index == 1 ? separatorFont : rowFont, storage: storage)
        }
    }

    private static func applyHeadingStyle(for line: String, lineRange: NSRange, storage: NSTextStorage?) -> Bool {
        guard let match = headingRegex.firstMatch(
            in: line,
            range: NSRange(location: 0, length: (line as NSString).length)
        ) else {
            return false
        }

        let level = match.range(at: 2).length
        let fontSize = headingSizes[min(max(level - 1, 0), headingSizes.count - 1)]
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = level <= 2 ? 16 : 10
        paragraphStyle.paragraphSpacingBefore = level <= 2 ? 10 : 4
        paragraphStyle.lineBreakMode = .byWordWrapping

        applyAttributes(
            [
                .font: NSFont.systemFont(ofSize: fontSize, weight: level == 1 ? .bold : .semibold),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ],
            to: lineRange,
            storage: storage
        )

        applyAttributes(
            syntaxAttributes(font: NSFont.systemFont(ofSize: fontSize, weight: .semibold)),
            to: shiftedRange(match.range(at: 2), by: lineRange.location),
            storage: storage
        )

        return true
    }

    private static func applyBlockquoteStyle(for line: String, lineRange: NSRange, storage: NSTextStorage?) -> Bool {
        guard let match = blockquoteRegex.firstMatch(
            in: line,
            range: NSRange(location: 0, length: (line as NSString).length)
        ) else {
            return false
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 18
        paragraphStyle.firstLineHeadIndent = 18
        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.lineBreakMode = .byWordWrapping

        applyAttributes(
            [
                .font: italicFont(size: 18),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ],
            to: lineRange,
            storage: storage
        )

        applyAttributes(
            syntaxAttributes(font: bodyFont),
            to: shiftedRange(match.range(at: 1), by: lineRange.location),
            storage: storage
        )

        return true
    }

    private static func applyChecklistStyle(for line: String, lineRange: NSRange, storage: NSTextStorage?) -> Bool {
        guard let match = checklistRegex.firstMatch(
            in: line,
            range: NSRange(location: 0, length: (line as NSString).length)
        ) else {
            return false
        }

        let prefixRange = shiftedRange(match.range(at: 1), by: lineRange.location)
        let isCompleted = line.contains("[x]") || line.contains("[X]")
        let paragraphStyle = listParagraphStyle(indent: 24)

        applyAttributes(
            [
                .font: bodyFont,
                .foregroundColor: isCompleted ? NSColor.secondaryLabelColor : NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ],
            to: lineRange,
            storage: storage
        )

        if isCompleted {
            applyAttributes(
                [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: NSColor.secondaryLabelColor
                ],
                to: lineRange,
                storage: storage
            )
        }

        applyAttributes(
            syntaxAttributes(font: bodyFont, color: isCompleted ? NSColor.systemGreen : nil),
            to: prefixRange,
            storage: storage
        )

        return true
    }

    private static func applyListStyle(for line: String, lineRange: NSRange, storage: NSTextStorage?) -> Bool {
        guard let match = listRegex.firstMatch(
            in: line,
            range: NSRange(location: 0, length: (line as NSString).length)
        ) else {
            return false
        }

        applyAttributes(
            [.paragraphStyle: listParagraphStyle(indent: 24)],
            to: lineRange,
            storage: storage
        )
        applyAttributes(
            syntaxAttributes(font: bodyFont),
            to: shiftedRange(match.range(at: 1), by: lineRange.location),
            storage: storage
        )

        return true
    }

    private static func applyInlineStyles(
        in text: String,
        storage: NSTextStorage?,
        protectedRanges: [NSRange],
        searchRange: NSRange
    ) {
        applyRegex(
            boldRegex,
            in: text,
            searchRange: searchRange,
            protectedRanges: protectedRanges
        ) { match in
            let wholeRange = match.range
            let contentRange = match.range(at: 1)
            applyAttributes(
                syntaxAttributes(font: bodyFont),
                to: wholeRange,
                storage: storage
            )
            applyAttributes(
                [.font: NSFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: NSColor.labelColor],
                to: contentRange,
                storage: storage
            )
        }

        applyRegex(
            italicRegex,
            in: text,
            searchRange: searchRange,
            protectedRanges: protectedRanges
        ) { match in
            let wholeRange = match.range
            let contentRange = match.range(at: 1)
            applyAttributes(
                syntaxAttributes(font: bodyFont),
                to: wholeRange,
                storage: storage
            )
            applyAttributes(
                [.font: italicFont(size: 18), .foregroundColor: NSColor.labelColor],
                to: contentRange,
                storage: storage
            )
        }

        applyRegex(
            inlineCodeRegex,
            in: text,
            searchRange: searchRange,
            protectedRanges: protectedRanges
        ) { match in
            let wholeRange = match.range
            let contentRange = match.range(at: 1)
            applyAttributes(
                syntaxAttributes(font: codeInlineFont),
                to: wholeRange,
                storage: storage
            )
            applyAttributes(
                [
                    .font: codeInlineFont,
                    .foregroundColor: NSColor.systemPink,
                    .backgroundColor: NSColor.controlBackgroundColor
                ],
                to: contentRange,
                storage: storage
            )
        }

        applyRegex(
            markdownLinkRegex,
            in: text,
            searchRange: searchRange,
            protectedRanges: protectedRanges
        ) { match in
            let wholeRange = match.range
            let labelRange = match.range(at: 1)
            let destinationRange = match.range(at: 2)
            applyAttributes(
                syntaxAttributes(font: bodyFont),
                to: wholeRange,
                storage: storage
            )
            applyAttributes(
                [
                    .font: bodyFont,
                    .foregroundColor: NSColor.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ],
                to: labelRange,
                storage: storage
            )
            applyAttributes(
                [
                    .font: NSFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: NSColor.secondaryLabelColor
                ],
                to: destinationRange,
                storage: storage
            )
        }

        applyRegex(
            wikiLinkRegex,
            in: text,
            searchRange: searchRange,
            protectedRanges: protectedRanges
        ) { match in
            let wholeRange = match.range
            let contentRange = match.range(at: 1)
            applyAttributes(
                syntaxAttributes(font: bodyFont),
                to: wholeRange,
                storage: storage
            )
            applyAttributes(
                [
                    .font: bodyFont,
                    .foregroundColor: NSColor.systemTeal,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ],
                to: contentRange,
                storage: storage
            )
        }

        applyRegex(
            tagRegex,
            in: text,
            searchRange: searchRange,
            protectedRanges: protectedRanges
        ) { match in
            applyAttributes(
                [
                    .font: NSFont.systemFont(ofSize: 16, weight: .medium),
                    .foregroundColor: NSColor.systemBlue,
                    .backgroundColor: NSColor.systemBlue.withAlphaComponent(0.10)
                ],
                to: match.range,
                storage: storage
            )
        }
    }

    private static func applyRegex(
        _ regex: NSRegularExpression,
        in text: String,
        searchRange: NSRange,
        protectedRanges: [NSRange],
        handler: (NSTextCheckingResult) -> Void
    ) {
        regex.matches(in: text, range: searchRange).forEach { match in
            guard !intersectsProtectedRanges(match.range, protectedRanges: protectedRanges) else {
                return
            }

            handler(match)
        }
    }

    private static func lineSlices(in text: String) -> [LineSlice] {
        let nsText = text as NSString
        guard nsText.length > 0 else {
            return []
        }

        var lines: [LineSlice] = []
        var location = 0
        while location < nsText.length {
            let fullLineRange = nsText.lineRange(for: NSRange(location: location, length: 0))
            var visibleRange = fullLineRange

            if visibleRange.length > 0 {
                let lastCharacterRange = NSRange(location: NSMaxRange(visibleRange) - 1, length: 1)
                if nsText.substring(with: lastCharacterRange) == "\n" {
                    visibleRange.length -= 1
                }
            }

            lines.append(LineSlice(text: nsText.substring(with: visibleRange), range: visibleRange))
            location = NSMaxRange(fullLineRange)
        }

        return lines
    }

    private static func shouldUseFullDocumentPass(for editedRange: NSRange, in text: String) -> Bool {
        let nsText = text as NSString
        let clampedRange = clamp(editedRange, maxLength: nsText.length)

        if clampedRange.length > 0,
           nsText.substring(with: clampedRange).contains("\n") {
            return true
        }

        let editedLines = lineNumbers(for: clampedRange, in: text)

        if frontMatterLineRange(in: text).map({ rangesIntersect($0, editedLines) }) == true {
            return true
        }

        let analysis = MarkdownReviewParser.analyze(text)

        if analysis.tables.contains(where: { rangesIntersect($0.startLine...$0.endLine, editedLines) }) {
            return true
        }

        if analysis.codeBlocks.contains(where: { rangesIntersect($0.startLine...$0.endLine, editedLines) }) {
            return true
        }

        return false
    }

    private static func expandedParagraphRange(for editedRange: NSRange, in nsText: NSString) -> NSRange {
        var range = nsText.paragraphRange(for: editedRange)

        if range.location > 0 {
            let previousLineRange = nsText.lineRange(for: NSRange(location: max(range.location - 1, 0), length: 0))
            range = NSUnionRange(range, previousLineRange)
        }

        if NSMaxRange(range) < nsText.length {
            let nextLocation = min(NSMaxRange(range), nsText.length - 1)
            let nextLineRange = nsText.lineRange(for: NSRange(location: nextLocation, length: 0))
            range = NSUnionRange(range, nextLineRange)
        }

        return clamp(range, maxLength: nsText.length)
    }

    private static func lineNumbers(for range: NSRange, in text: String) -> ClosedRange<Int> {
        let nsText = text as NSString
        let safeRange = clamp(range, maxLength: nsText.length)
        let startLine = lineNumber(at: safeRange.location, in: text)
        let endLocation = max(safeRange.location, NSMaxRange(safeRange) - 1)
        let endLine = lineNumber(at: endLocation, in: text)
        return startLine...max(startLine, endLine)
    }

    private static func lineNumber(at location: Int, in text: String) -> Int {
        let nsText = text as NSString
        let safeLocation = min(max(location, 0), nsText.length)
        let prefix = nsText.substring(to: safeLocation)
        return max(1, prefix.components(separatedBy: "\n").count)
    }

    private static func frontMatterLineRange(in text: String) -> ClosedRange<Int>? {
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---" else {
            return nil
        }

        for index in 1..<lines.count where lines[index].trimmingCharacters(in: .whitespacesAndNewlines) == "---" {
            return 1...(index + 1)
        }

        return 1...lines.count
    }

    private static func applyAttributes(
        _ attributes: [NSAttributedString.Key: Any],
        to range: NSRange,
        storage: NSTextStorage?
    ) {
        guard range.location != NSNotFound, range.length > 0 else {
            return
        }

        storage?.addAttributes(attributes, range: range)
    }

    private static func clamp(_ range: NSRange, maxLength: Int) -> NSRange {
        let location = min(max(range.location, 0), maxLength)
        let length = min(max(range.length, 0), max(0, maxLength - location))
        return NSRange(location: location, length: length)
    }

    private static func shiftedRange(_ range: NSRange, by offset: Int) -> NSRange {
        NSRange(location: range.location + offset, length: range.length)
    }

    private static func intersectsProtectedRanges(_ range: NSRange, protectedRanges: [NSRange]) -> Bool {
        protectedRanges.contains { protectedRange in
            NSIntersectionRange(range, protectedRange).length > 0
        }
    }

    private static func parseTableCells(from line: String) -> [String] {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard trimmedLine.contains("|") else {
            return []
        }

        var content = trimmedLine
        if content.hasPrefix("|") {
            content.removeFirst()
        }
        if content.hasSuffix("|") {
            content.removeLast()
        }

        var cells: [String] = []
        var currentCell = ""
        var isEscaping = false

        for character in content {
            if isEscaping {
                currentCell.append(character)
                isEscaping = false
                continue
            }

            if character == "\\" {
                isEscaping = true
                continue
            }

            if character == "|" {
                cells.append(currentCell.trimmingCharacters(in: .whitespaces))
                currentCell = ""
            } else {
                currentCell.append(character)
            }
        }

        cells.append(currentCell.trimmingCharacters(in: .whitespaces))
        return cells
    }

    private static func isSeparatorCell(_ cell: String) -> Bool {
        let trimmed = cell.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            return false
        }

        return trimmed.allSatisfy { character in
            character == "-" || character == ":"
        } && trimmed.contains("-")
    }

    private static func rangesIntersect(_ lhs: ClosedRange<Int>, _ rhs: ClosedRange<Int>) -> Bool {
        lhs.overlaps(rhs)
    }

    private static func applyPipeSyntaxStyle(in line: LineSlice, font: NSFont, storage: NSTextStorage?) {
        let nsLine = line.text as NSString

        for location in 0..<nsLine.length {
            let characterRange = NSRange(location: location, length: 1)
            guard nsLine.substring(with: characterRange) == "|" else {
                continue
            }

            applyAttributes(
                syntaxAttributes(font: font),
                to: shiftedRange(characterRange, by: line.range.location),
                storage: storage
            )
        }
    }

    private static func italicFont(size: CGFloat) -> NSFont {
        NSFontManager.shared.convert(NSFont.systemFont(ofSize: size, weight: .regular), toHaveTrait: .italicFontMask)
    }

    private static func listParagraphStyle(indent: CGFloat) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = 0
        style.headIndent = indent
        style.paragraphSpacing = 8
        style.lineBreakMode = .byWordWrapping
        return style
    }

    private static func tableParagraphStyle(topPadding: CGFloat, bottomPadding: CGFloat) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = 8
        style.headIndent = 8
        style.tailIndent = -8
        style.paragraphSpacingBefore = topPadding
        style.paragraphSpacing = bottomPadding
        style.lineBreakMode = .byTruncatingTail
        return style
    }

    private static func syntaxAttributes(font: NSFont, color: NSColor? = nil) -> [NSAttributedString.Key: Any] {
        [
            .font: font,
            .foregroundColor: (color ?? NSColor.secondaryLabelColor).withAlphaComponent(0.55)
        ]
    }

    private static var markdownBaseAttributes: [NSAttributedString.Key: Any] {
        [
            .font: sourceFont,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: sourceParagraphStyle
        ]
    }

    private static var documentBaseAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: documentParagraphStyle
        ]
    }

    private static var documentTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: NSColor.labelColor
        ]
    }

    private static var codeBlockAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .regular),
            .foregroundColor: NSColor.textColor,
            .backgroundColor: NSColor.controlBackgroundColor,
            .paragraphStyle: codeParagraphStyle
        ]
    }

    private static var codeFenceAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.70),
            .backgroundColor: NSColor.controlBackgroundColor,
            .paragraphStyle: codeParagraphStyle
        ]
    }

    private static var frontMatterAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
            .backgroundColor: NSColor.controlBackgroundColor.withAlphaComponent(0.45),
            .paragraphStyle: sourceParagraphStyle
        ]
    }

    private static var frontMatterBoundaryAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.tertiaryLabelColor,
            .backgroundColor: NSColor.controlBackgroundColor.withAlphaComponent(0.45),
            .paragraphStyle: sourceParagraphStyle
        ]
    }

    private static var selectedTextAttributes: [NSAttributedString.Key: Any] {
        [
            .backgroundColor: NSColor.controlAccentColor.withAlphaComponent(0.28),
            .foregroundColor: NSColor.labelColor
        ]
    }

    private static var sourceParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.lineSpacing = 4
        return style
    }

    private static var documentParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.lineSpacing = 6
        style.paragraphSpacing = 10
        return style
    }

    private static var codeParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.lineSpacing = 4
        style.paragraphSpacing = 8
        style.headIndent = 18
        style.firstLineHeadIndent = 18
        return style
    }

    private static var codeInlineFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
    }
}
