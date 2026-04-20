import SwiftUI

struct TableReviewCard: View {
    let table: TableBlock
    let jumpToLine: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Table", systemImage: "tablecells")
                    .font(.body.weight(.medium))

                Spacer()

                Button("L\(table.startLine)") {
                    jumpToLine(table.startLine)
                }
                .buttonStyle(.link)
            }

            Text("\(table.columnCount) columns · \(table.rowCount) rows")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow {
                        ForEach(Array(table.headers.enumerated()), id: \.offset) { _, cell in
                            tableCell(cell, emphasized: true)
                        }
                    }

                    ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                        GridRow {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                tableCell(cell, emphasized: false)
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color.accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(maxHeight: tableHeight)
        }
        .padding(.vertical, 4)
    }

    private var tableHeight: CGFloat {
        min(CGFloat(table.rowCount + 1) * 34 + 24, 280)
    }

    private func tableCell(_ value: String, emphasized: Bool) -> some View {
        Text(value.isEmpty ? " " : value)
            .font(emphasized ? .caption.weight(.semibold) : .caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                emphasized ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }
}

struct CodeBlockReviewCard: View {
    let block: CodeBlockItem
    let jumpToLine: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(block.isSQL ? "SQL Block" : block.displayLanguage, systemImage: block.isSQL ? "cylinder.split.1x2" : "chevron.left.forwardslash.chevron.right")
                    .font(.body.weight(.medium))

                Spacer()

                Button("L\(block.startLine)") {
                    jumpToLine(block.startLine)
                }
                .buttonStyle(.link)
            }

            Text("Lines \(block.startLine)-\(block.endLine)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Text(displayText)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(10)
            }
            .frame(maxHeight: codeHeight)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.vertical, 4)
    }

    private var displayText: String {
        let text = block.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? block.preview : text
    }

    private var codeHeight: CGFloat {
        let lineCount = max(1, displayText.components(separatedBy: "\n").count)
        return min(CGFloat(lineCount) * 18 + 24, 280)
    }
}
