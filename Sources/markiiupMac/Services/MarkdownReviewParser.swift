import Foundation

enum MarkdownReviewParser {
    private static let markdownLinkRegex = try! NSRegularExpression(pattern: "(?<!!)\\[([^\\]]+)\\]\\(([^)]+)\\)")
    private static let wikiLinkRegex = try! NSRegularExpression(pattern: "\\[\\[([^\\]]+)\\]\\]")
    private static let tagRegex = try! NSRegularExpression(pattern: "(?<!\\w)#([A-Za-z0-9_-]+)\\b")

    static func analyze(_ text: String) -> MarkdownAnalysis {
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalizedText.components(separatedBy: "\n")
        let frontMatterResult = parseFrontMatter(in: lines)
        let bodyText = bodyText(from: lines, frontMatterEndIndex: frontMatterResult.endIndex)

        var headings: [OutlineItem] = []
        var tasks: [TaskItem] = []
        var links: [LinkItem] = []
        var tables: [TableBlock] = []
        var codeBlocks: [CodeBlockItem] = []
        var tagMap: [String: (count: Int, firstLine: Int)] = [:]

        let firstBodyIndex = frontMatterResult.endIndex.map { $0 + 1 } ?? 0
        var index = firstBodyIndex

        while index < lines.count {
            if let codeBlockResult = parseCodeBlock(startingAt: index, in: lines) {
                codeBlocks.append(codeBlockResult.block)
                index = codeBlockResult.nextIndex
                continue
            }

            if let tableResult = parseTable(startingAt: index, in: lines) {
                tables.append(tableResult.table)

                for lineIndex in index..<tableResult.nextIndex {
                    let lineNumber = lineIndex + 1
                    let line = lines[lineIndex]

                    parseLinks(in: line, lineNumber: lineNumber).forEach { links.append($0) }
                    parseTags(in: line, lineNumber: lineNumber).forEach { tagName in
                        if let existing = tagMap[tagName] {
                            tagMap[tagName] = (existing.count + 1, existing.firstLine)
                        } else {
                            tagMap[tagName] = (1, lineNumber)
                        }
                    }
                }

                index = tableResult.nextIndex
                continue
            }

            let line = lines[index]
            let lineNumber = index + 1

            if let heading = parseHeading(in: line, lineNumber: lineNumber) {
                headings.append(heading)
            }

            if let task = parseTask(in: line, lineNumber: lineNumber) {
                tasks.append(task)
            }

            parseLinks(in: line, lineNumber: lineNumber).forEach { links.append($0) }

            parseTags(in: line, lineNumber: lineNumber).forEach { tagName in
                if let existing = tagMap[tagName] {
                    tagMap[tagName] = (existing.count + 1, existing.firstLine)
                } else {
                    tagMap[tagName] = (1, lineNumber)
                }
            }

            index += 1
        }

        let wordCount = bodyText.split(whereSeparator: \.isWhitespace).count
        let readingMinutes = wordCount == 0 ? 0 : Int(ceil(Double(wordCount) / 200.0))
        let tags = tagMap
            .map { TagItem(name: $0.key, count: $0.value.count, firstLine: $0.value.firstLine) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return MarkdownAnalysis(
            metrics: DocumentMetrics(
                wordCount: wordCount,
                characterCount: normalizedText.count,
                lineCount: lines.count,
                readingMinutes: readingMinutes,
                headingCount: headings.count,
                openTaskCount: tasks.filter { !$0.completed }.count,
                completedTaskCount: tasks.filter(\.completed).count,
                linkCount: links.count,
                tagCount: tags.count,
                frontMatterKeyCount: frontMatterResult.entries.count,
                tableCount: tables.count,
                codeBlockCount: codeBlocks.count,
                sqlBlockCount: codeBlocks.filter(\.isSQL).count
            ),
            frontMatter: frontMatterResult.entries,
            headings: headings,
            tasks: tasks,
            links: links,
            tags: tags,
            tables: tables,
            codeBlocks: codeBlocks
        )
    }

    private static func parseFrontMatter(in lines: [String]) -> (entries: [FrontMatterEntry], endIndex: Int?) {
        guard lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---" else {
            return ([], nil)
        }

        var entries: [FrontMatterEntry] = []

        for index in 1..<lines.count {
            let rawLine = lines[index]
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed == "---" {
                return (entries, index)
            }

            guard let separatorIndex = rawLine.firstIndex(of: ":") else {
                continue
            }

            let key = rawLine[..<separatorIndex].trimmingCharacters(in: .whitespaces)
            let value = rawLine[rawLine.index(after: separatorIndex)...]
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

            guard !key.isEmpty else {
                continue
            }

            entries.append(FrontMatterEntry(key: key, value: value))
        }

        return ([], nil)
    }

    private static func bodyText(from lines: [String], frontMatterEndIndex: Int?) -> String {
        guard let endIndex = frontMatterEndIndex, endIndex + 1 < lines.count else {
            return frontMatterEndIndex == nil ? lines.joined(separator: "\n") : ""
        }

        return Array(lines[(endIndex + 1)...]).joined(separator: "\n")
    }

    private static func parseHeading(in line: String, lineNumber: Int) -> OutlineItem? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let hashes = trimmed.prefix { $0 == "#" }
        let level = hashes.count

        guard (1...6).contains(level) else {
            return nil
        }

        guard trimmed.dropFirst(level).first == " " else {
            return nil
        }

        let title = trimmed.dropFirst(level + 1).trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            return nil
        }

        return OutlineItem(title: title, level: level, lineNumber: lineNumber)
    }

    private static func parseTask(in line: String, lineNumber: Int) -> TaskItem? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let prefixes: [(String, Bool)] = [
            ("- [ ] ", false),
            ("* [ ] ", false),
            ("- [x] ", true),
            ("* [x] ", true),
            ("- [X] ", true),
            ("* [X] ", true)
        ]

        for (prefix, completed) in prefixes where trimmed.hasPrefix(prefix) {
            let title = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            return TaskItem(title: title.isEmpty ? "Untitled task" : title, completed: completed, lineNumber: lineNumber)
        }

        return nil
    }

    private static func parseLinks(in line: String, lineNumber: Int) -> [LinkItem] {
        let nsRange = NSRange(line.startIndex..., in: line)
        var items: [LinkItem] = []

        markdownLinkRegex.matches(in: line, range: nsRange).forEach { match in
            let label = substring(from: match.range(at: 1), in: line)
            let destination = substring(from: match.range(at: 2), in: line)

            items.append(
                LinkItem(
                    label: label.isEmpty ? destination : label,
                    destination: destination,
                    lineNumber: lineNumber,
                    kind: .markdown
                )
            )
        }

        wikiLinkRegex.matches(in: line, range: nsRange).forEach { match in
            let destination = substring(from: match.range(at: 1), in: line)
            items.append(
                LinkItem(
                    label: destination,
                    destination: destination,
                    lineNumber: lineNumber,
                    kind: .wiki
                )
            )
        }

        return items
    }

    private static func parseTags(in line: String, lineNumber: Int) -> [String] {
        let nsRange = NSRange(line.startIndex..., in: line)
        return tagRegex.matches(in: line, range: nsRange).compactMap { match in
            let tagName = substring(from: match.range(at: 1), in: line)
            return tagName.isEmpty ? nil : tagName
        }
    }

    private static func parseCodeBlock(
        startingAt index: Int,
        in lines: [String]
    ) -> (block: CodeBlockItem, nextIndex: Int)? {
        guard index < lines.count else {
            return nil
        }

        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```") else {
            return nil
        }

        let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        var contentLines: [String] = []
        var closingIndex = index

        while closingIndex + 1 < lines.count {
            closingIndex += 1
            let candidate = lines[closingIndex]

            if candidate.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                let block = CodeBlockItem(
                    language: language.isEmpty ? nil : language,
                    content: contentLines.joined(separator: "\n"),
                    startLine: index + 1,
                    endLine: closingIndex + 1
                )
                return (block, closingIndex + 1)
            }

            contentLines.append(candidate)
        }

        let block = CodeBlockItem(
            language: language.isEmpty ? nil : language,
            content: contentLines.joined(separator: "\n"),
            startLine: index + 1,
            endLine: lines.count
        )
        return (block, lines.count)
    }

    private static func parseTable(
        startingAt index: Int,
        in lines: [String]
    ) -> (table: TableBlock, nextIndex: Int)? {
        guard index + 1 < lines.count else {
            return nil
        }

        let headerCells = parseTableCells(from: lines[index])
        let separatorCells = parseTableCells(from: lines[index + 1])

        guard headerCells.count >= 2,
              separatorCells.count == headerCells.count,
              separatorCells.allSatisfy(isSeparatorCell)
        else {
            return nil
        }

        var rows: [[String]] = []
        var nextIndex = index + 2
        var maxColumnCount = headerCells.count

        while nextIndex < lines.count {
            let rowCells = parseTableCells(from: lines[nextIndex])
            guard rowCells.count >= 2 else {
                break
            }

            maxColumnCount = max(maxColumnCount, rowCells.count)
            rows.append(rowCells)
            nextIndex += 1
        }

        let normalizedHeaders = normalizeTableRow(headerCells, columnCount: maxColumnCount)
        let normalizedRows = rows.map { normalizeTableRow($0, columnCount: maxColumnCount) }
        let endLine = max(index + 2, nextIndex) 

        return (
            TableBlock(
                headers: normalizedHeaders,
                rows: normalizedRows,
                startLine: index + 1,
                endLine: endLine
            ),
            nextIndex
        )
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

    private static func normalizeTableRow(_ row: [String], columnCount: Int) -> [String] {
        guard row.count < columnCount else {
            return Array(row.prefix(columnCount))
        }

        return row + Array(repeating: "", count: columnCount - row.count)
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

    private static func substring(from range: NSRange, in text: String) -> String {
        guard let swiftRange = Range(range, in: text) else {
            return ""
        }

        return String(text[swiftRange])
    }
}
