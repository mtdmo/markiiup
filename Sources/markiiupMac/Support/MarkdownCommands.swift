import SwiftUI

struct MarkdownEditorActionHandler {
    let send: @MainActor (EditorCommand) -> Void
}

private struct MarkdownEditorActionHandlerKey: FocusedValueKey {
    typealias Value = MarkdownEditorActionHandler
}

extension FocusedValues {
    var markdownEditorActionHandler: MarkdownEditorActionHandler? {
        get { self[MarkdownEditorActionHandlerKey.self] }
        set { self[MarkdownEditorActionHandlerKey.self] = newValue }
    }
}

struct MarkdownFormattingCommands: Commands {
    @FocusedValue(\.markdownEditorActionHandler) private var actionHandler

    var body: some Commands {
        CommandMenu("Format") {
            Group {
                Button("Bold") { send(.bold) }
                    .keyboardShortcut("b", modifiers: .command)

                Button("Italic") { send(.italic) }
                    .keyboardShortcut("i", modifiers: .command)

                Button("Inline Code") { send(.code) }
                    .keyboardShortcut("e", modifiers: .command)

                Divider()

                Button("Heading 1") { send(.heading(level: 1)) }
                Button("Heading 2") { send(.heading(level: 2)) }
                Button("Heading 3") { send(.heading(level: 3)) }

                Divider()

                Button("Checklist") { send(.checklist) }
                    .keyboardShortcut("k", modifiers: [.command, .shift])

                Button("Quote") { send(.quote) }
                    .keyboardShortcut("'", modifiers: [.command, .shift])

                Button("Link") { send(.link) }
                    .keyboardShortcut("k", modifiers: .command)

                Divider()

                Button("Insert 3 x 3 Table") { send(.insertTable(columns: 3, rows: 3)) }
                    .keyboardShortcut("t", modifiers: [.command, .option])
            }
            .disabled(actionHandler == nil)
        }
    }

    private func send(_ command: EditorCommand) {
        actionHandler?.send(command)
    }
}
