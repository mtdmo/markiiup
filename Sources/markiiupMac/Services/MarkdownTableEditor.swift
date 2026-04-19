import Foundation

struct EditableMarkdownTable: Identifiable, Equatable {
    let startLine: Int
    let endLine: Int
    var headers: [String]
    var rows: [[String]]

    var id: Int { startLine }

    var columnCount: Int {
        max(headers.count, rows.map(\.count).max() ?? 0, 1)
    }

    var bodyRowCount: Int {
        rows.count
    }

    init(block: TableBlock) {
        startLine = block.startLine
        endLine = block.endLine
        headers = block.headers
        rows = block.rows
    }

    init(startLine: Int, endLine: Int, headers: [String], rows: [[String]]) {
        self.startLine = startLine
        self.endLine = endLine
        self.headers = headers
        self.rows = rows
    }

    func cellValue(row: Int, column: Int) -> String {
        let normalized = normalized()
        if row == 0 {
            return normalized.headers[column]
        }

        guard row - 1 < normalized.rows.count else {
            return ""
        }

        return normalized.rows[row - 1][column]
    }

    func updatingCell(row: Int, column: Int, value: String) -> EditableMarkdownTable {
        var normalized = normalized()
        let sanitizedValue = value.replacingOccurrences(of: "\n", with: " ")

        if row == 0 {
            normalized.headers[column] = sanitizedValue
        } else if row - 1 < normalized.rows.count {
            normalized.rows[row - 1][column] = sanitizedValue
        }

        return normalized
    }

    func addingBodyRow(after bodyIndex: Int?) -> EditableMarkdownTable {
        var normalized = normalized()
        let newRow = Array(repeating: "", count: normalized.columnCount)
        let insertionIndex = min(max((bodyIndex ?? normalized.rows.count - 1) + 1, 0), normalized.rows.count)
        normalized.rows.insert(newRow, at: insertionIndex)
        return normalized
    }

    func removingBodyRow(_ bodyIndex: Int?) -> EditableMarkdownTable {
        var normalized = normalized()
        guard normalized.rows.count > 1 else {
            return normalized
        }

        let rowToRemove = min(max(bodyIndex ?? normalized.rows.count - 1, 0), normalized.rows.count - 1)
        normalized.rows.remove(at: rowToRemove)
        return normalized
    }

    func addingColumn(after columnIndex: Int?) -> EditableMarkdownTable {
        var normalized = normalized()
        let insertionIndex = min(max((columnIndex ?? normalized.columnCount - 1) + 1, 0), normalized.columnCount)
        normalized.headers.insert("Column \(insertionIndex + 1)", at: insertionIndex)

        for rowIndex in normalized.rows.indices {
            normalized.rows[rowIndex].insert("", at: insertionIndex)
        }

        return normalized
    }

    func removingColumn(_ columnIndex: Int?) -> EditableMarkdownTable {
        var normalized = normalized()
        guard normalized.columnCount > 1 else {
            return normalized
        }

        let targetIndex = min(max(columnIndex ?? normalized.columnCount - 1, 0), normalized.columnCount - 1)
        normalized.headers.remove(at: targetIndex)

        for rowIndex in normalized.rows.indices where targetIndex < normalized.rows[rowIndex].count {
            normalized.rows[rowIndex].remove(at: targetIndex)
        }

        return normalized.normalized()
    }

    func normalized() -> EditableMarkdownTable {
        let count = columnCount
        let normalizedHeaders = normalizedRow(headers, count: count, fallbackPrefix: "Column")
        let normalizedRows = rows.map { normalizedRow($0, count: count, fallbackPrefix: "") }
        return EditableMarkdownTable(startLine: startLine, endLine: endLine, headers: normalizedHeaders, rows: normalizedRows)
    }

    private func normalizedRow(_ row: [String], count: Int, fallbackPrefix: String) -> [String] {
        if row.count == count {
            return row
        }

        var normalized = row

        while normalized.count < count {
            if fallbackPrefix.isEmpty {
                normalized.append("")
            } else {
                normalized.append("\(fallbackPrefix) \(normalized.count + 1)")
            }
        }

        if normalized.count > count {
            normalized = Array(normalized.prefix(count))
        }

        return normalized
    }
}

struct MarkdownTableInsertion {
    let text: String
    let selectionRange: NSRange
}

enum MarkdownTableEditor {
    static func activeTable(in text: String, lineNumber: Int) -> EditableMarkdownTable? {
        MarkdownReviewParser
            .analyze(text)
            .tables
            .first { $0.startLine...$0.endLine ~= lineNumber }
            .map(EditableMarkdownTable.init(block:))
    }

    static func replacingTable(in text: String, with table: EditableMarkdownTable) -> String {
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalizedText.components(separatedBy: "\n")

        guard !lines.isEmpty else {
            return render(table.normalized()).joined(separator: "\n")
        }

        let startIndex = max(table.startLine - 1, 0)
        let endIndex = min(table.endLine - 1, lines.count - 1)
        guard startIndex <= endIndex else {
            return normalizedText
        }

        let replacementLines = render(table.normalized())
        let prefix = Array(lines[..<startIndex])
        let suffix = endIndex + 1 < lines.count ? Array(lines[(endIndex + 1)...]) : []
        return (prefix + replacementLines + suffix).joined(separator: "\n")
    }

    static func insertTable(
        in text: String,
        selectedRange: NSRange,
        columns: Int,
        rows: Int
    ) -> MarkdownTableInsertion {
        let columnCount = max(columns, 1)
        let rowCount = max(rows, 1)
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        let nsText = normalizedText as NSString
        let clampedSelection = clamp(selectedRange, maxLength: nsText.length)
        let lineRange = nsText.lineRange(for: clampedSelection)
        let visibleLineRange = visibleRange(for: lineRange, in: nsText)
        let currentLine = nsText.substring(with: visibleLineRange)
        let shouldReplaceBlankLine = currentLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let table = EditableMarkdownTable(
            startLine: 1,
            endLine: rowCount + 2,
            headers: (0..<columnCount).map { "Column \($0 + 1)" },
            rows: Array(repeating: Array(repeating: "", count: columnCount), count: rowCount)
        )
        let tableMarkdown = render(table).joined(separator: "\n")

        let replacementRange: NSRange
        let replacement: String
        let selectionLocation: Int

        if shouldReplaceBlankLine {
            replacementRange = lineRange
            replacement = tableMarkdown + "\n"
            selectionLocation = lineRange.location + 2
        } else {
            let insertionLocation = NSMaxRange(lineRange)
            let lineEndsWithNewline = lineRange.length > 0 &&
                insertionLocation > 0 &&
                nsText.substring(with: NSRange(location: insertionLocation - 1, length: 1)) == "\n"
            let prefix = lineEndsWithNewline ? "" : "\n"
            replacementRange = NSRange(location: insertionLocation, length: 0)
            replacement = prefix + tableMarkdown + "\n"
            selectionLocation = insertionLocation + (prefix as NSString).length + 2
        }

        let updatedText = nsText.replacingCharacters(in: replacementRange, with: replacement)
        let headerLength = ("Column 1" as NSString).length
        return MarkdownTableInsertion(
            text: updatedText,
            selectionRange: NSRange(location: selectionLocation, length: headerLength)
        )
    }

    private static func render(_ table: EditableMarkdownTable) -> [String] {
        let normalized = table.normalized()
        let separator = Array(repeating: "---", count: normalized.columnCount)

        return [
            line(for: normalized.headers),
            line(for: separator)
        ] + normalized.rows.map(line(for:))
    }

    private static func line(for cells: [String]) -> String {
        "| " + cells.map(escapedCell).joined(separator: " | ") + " |"
    }

    private static func escapedCell(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "|", with: "\\|")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func clamp(_ range: NSRange, maxLength: Int) -> NSRange {
        let location = min(max(range.location, 0), maxLength)
        let length = min(max(range.length, 0), max(0, maxLength - location))
        return NSRange(location: location, length: length)
    }

    private static func visibleRange(for lineRange: NSRange, in nsText: NSString) -> NSRange {
        guard lineRange.length > 0 else {
            return lineRange
        }

        let lastCharacterRange = NSRange(location: NSMaxRange(lineRange) - 1, length: 1)
        if nsText.substring(with: lastCharacterRange) == "\n" {
            return NSRange(location: lineRange.location, length: lineRange.length - 1)
        }

        return lineRange
    }
}
