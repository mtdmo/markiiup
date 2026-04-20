import AppKit
import SwiftUI

struct EditorPaneView: View {
    @Binding var text: String
    @ObservedObject var editorState: MarkdownEditorState
    let metrics: DocumentMetrics
    let mode: WorkspaceMode

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Label(title, systemImage: iconName)
                        .font(.headline)

                    Spacer()

                    Text("Line \(editorState.currentLine)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    Text("\(metrics.lineCount) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if let activeTable {
                Divider()

                CanvasTableEditorView(
                    table: activeTable,
                    onUpdateCell: { row, column, value in
                        updateActiveTable { table in
                            table.updatingCell(row: row, column: column, value: value)
                        }
                    },
                    onAddRow: { bodyIndex in
                        updateActiveTable { table in
                            table.addingBodyRow(after: bodyIndex)
                        }
                    },
                    onRemoveRow: { bodyIndex in
                        updateActiveTable { table in
                            table.removingBodyRow(bodyIndex)
                        }
                    },
                    onAddColumn: { columnIndex in
                        updateActiveTable { table in
                            table.addingColumn(after: columnIndex)
                        }
                    },
                    onRemoveColumn: { columnIndex in
                        updateActiveTable { table in
                            table.removingColumn(columnIndex)
                        }
                    },
                    onRevealSource: {
                        editorState.send(.jumpToLine(activeTable.startLine))
                    }
                )
            }

            Divider()

            NativeMarkdownTextView(text: $text, editorState: editorState, presentation: mode)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var title: String {
        switch mode {
        case .document:
            return "Document Canvas"
        case .markdown:
            return "Markdown Source"
        }
    }

    private var subtitle: String {
        switch mode {
        case .document:
            return "Formatted editing backed by the Markdown file. Use the toolbar, then save straight back to .md."
        case .markdown:
            return "Raw Markdown view for exact control over the file."
        }
    }

    private var iconName: String {
        switch mode {
        case .document:
            return "doc.richtext"
        case .markdown:
            return "doc.plaintext"
        }
    }

    private var activeTable: EditableMarkdownTable? {
        guard mode == .document else {
            return nil
        }

        return MarkdownTableEditor.activeTable(in: text, lineNumber: editorState.currentLine)
    }

    private func updateActiveTable(_ transform: (EditableMarkdownTable) -> EditableMarkdownTable) {
        guard let activeTable else {
            return
        }

        text = MarkdownTableEditor.replacingTable(in: text, with: transform(activeTable))
    }
}
