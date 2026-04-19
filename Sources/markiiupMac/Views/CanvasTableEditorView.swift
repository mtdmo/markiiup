import SwiftUI

private struct TableCellSelection: Equatable {
    let row: Int
    let column: Int
}

struct CanvasTableEditorView: View {
    let table: EditableMarkdownTable
    let onUpdateCell: (Int, Int, String) -> Void
    let onAddRow: (Int?) -> Void
    let onRemoveRow: (Int?) -> Void
    let onAddColumn: (Int?) -> Void
    let onRemoveColumn: (Int?) -> Void
    let onRevealSource: () -> Void

    @State private var selectedCell: TableCellSelection?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Table Editor", systemImage: "tablecells")
                        .font(.headline)

                    Text("Editing lines \(table.startLine)-\(table.endLine) in the Markdown file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Reveal In Source") {
                    onRevealSource()
                }
                .buttonStyle(.link)
            }

            HStack(spacing: 10) {
                Button("Add Row") {
                    onAddRow(selectedBodyRowIndex)
                }

                Button("Delete Row") {
                    onRemoveRow(selectedBodyRowIndex)
                }
                .disabled(table.bodyRowCount <= 1)

                Divider()
                    .frame(height: 14)

                Button("Add Column") {
                    onAddColumn(selectedColumnIndex)
                }

                Button("Delete Column") {
                    onRemoveColumn(selectedColumnIndex)
                }
                .disabled(table.columnCount <= 1)

                Spacer()

                Text(selectionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.bordered)

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        ForEach(0..<table.columnCount, id: \.self) { column in
                            cellField(
                                row: 0,
                                column: column,
                                value: table.cellValue(row: 0, column: column),
                                prompt: "Column \(column + 1)",
                                emphasized: true
                            )
                        }
                    }

                    ForEach(0..<table.bodyRowCount, id: \.self) { bodyRow in
                        GridRow {
                            ForEach(0..<table.columnCount, id: \.self) { column in
                                cellField(
                                    row: bodyRow + 1,
                                    column: column,
                                    value: table.cellValue(row: bodyRow + 1, column: column),
                                    prompt: "",
                                    emphasized: false
                                )
                            }
                        }
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: tableHeight)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.thinMaterial)
    }

    private var selectedBodyRowIndex: Int? {
        guard let selectedCell, selectedCell.row > 0 else {
            return nil
        }

        return selectedCell.row - 1
    }

    private var selectedColumnIndex: Int? {
        selectedCell?.column
    }

    private var selectionLabel: String {
        guard let selectedCell else {
            return "Click a cell to target row and column actions."
        }

        if selectedCell.row == 0 {
            return "Selected header column \(selectedCell.column + 1)"
        }

        return "Selected row \(selectedCell.row) · column \(selectedCell.column + 1)"
    }

    private var tableHeight: CGFloat {
        let renderedRows = max(table.bodyRowCount + 1, 2)
        return min(CGFloat(renderedRows) * 46 + 24, 320)
    }

    @ViewBuilder
    private func cellField(
        row: Int,
        column: Int,
        value: String,
        prompt: String,
        emphasized: Bool
    ) -> some View {
        let isSelected = selectedCell == TableCellSelection(row: row, column: column)

        TextField(
            "",
            text: Binding(
                get: { value },
                set: { onUpdateCell(row, column, $0) }
            ),
            prompt: prompt.isEmpty ? nil : Text(prompt)
        )
        .textFieldStyle(.plain)
        .font(.system(size: emphasized ? 13 : 12, weight: emphasized ? .semibold : .regular, design: .monospaced))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 150, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(emphasized ? Color.accentColor.opacity(0.10) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture {
            selectedCell = TableCellSelection(row: row, column: column)
        }
    }
}
