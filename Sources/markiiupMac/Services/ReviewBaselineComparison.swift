import Foundation

enum ReviewBaselineComparison {
    static func compare(
        baseline: ReviewBaselineSnapshot,
        baselineAnalysis: MarkdownAnalysis,
        currentText: String,
        currentAnalysis: MarkdownAnalysis
    ) -> ReviewBaselineSummary {
        let lineDiff = diffLines(before: baseline.text, after: currentText)
        let headingDiff = diffCounts(
            before: baselineAnalysis.headings.map { "\($0.level)|\($0.title)" },
            after: currentAnalysis.headings.map { "\($0.level)|\($0.title)" }
        )
        let tableDiff = diffCounts(
            before: baselineAnalysis.tables.map(tableSignature),
            after: currentAnalysis.tables.map(tableSignature)
        )
        let sqlDiff = diffCounts(
            before: baselineAnalysis.sqlCodeBlocks.map(codeBlockSignature),
            after: currentAnalysis.sqlCodeBlocks.map(codeBlockSignature)
        )

        return ReviewBaselineSummary(
            capturedAt: baseline.capturedAt,
            addedLineCount: lineDiff.added,
            removedLineCount: lineDiff.removed,
            addedHeadingCount: headingDiff.added,
            removedHeadingCount: headingDiff.removed,
            addedTableCount: tableDiff.added,
            removedTableCount: tableDiff.removed,
            addedSQLBlockCount: sqlDiff.added,
            removedSQLBlockCount: sqlDiff.removed,
            openTaskDelta: currentAnalysis.metrics.openTaskCount - baselineAnalysis.metrics.openTaskCount,
            completedTaskDelta: currentAnalysis.metrics.completedTaskCount - baselineAnalysis.metrics.completedTaskCount,
            linkDelta: currentAnalysis.metrics.linkCount - baselineAnalysis.metrics.linkCount
        )
    }

    private static func diffLines(before: String, after: String) -> (added: Int, removed: Int) {
        let baselineLines = normalizedLines(in: before)
        let currentLines = normalizedLines(in: after)
        let difference = currentLines.difference(from: baselineLines)

        var added = 0
        var removed = 0

        for change in difference {
            switch change {
            case .insert:
                added += 1
            case .remove:
                removed += 1
            }
        }

        return (added, removed)
    }

    private static func diffCounts(before: [String], after: [String]) -> (added: Int, removed: Int) {
        let beforeCounts = counts(for: before)
        let afterCounts = counts(for: after)
        let allKeys = Set(beforeCounts.keys).union(afterCounts.keys)

        var added = 0
        var removed = 0

        for key in allKeys {
            let baselineValue = beforeCounts[key, default: 0]
            let currentValue = afterCounts[key, default: 0]

            if currentValue > baselineValue {
                added += currentValue - baselineValue
            } else if baselineValue > currentValue {
                removed += baselineValue - currentValue
            }
        }

        return (added, removed)
    }

    private static func counts(for items: [String]) -> [String: Int] {
        Dictionary(items.map { ($0, 1) }, uniquingKeysWith: +)
    }

    private static func normalizedLines(in text: String) -> [String] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
    }

    private static func tableSignature(_ table: TableBlock) -> String {
        ([table.headers] + table.rows)
            .map { $0.joined(separator: "\u{241F}") }
            .joined(separator: "\u{241E}")
    }

    private static func codeBlockSignature(_ block: CodeBlockItem) -> String {
        "\(block.normalizedLanguage ?? "plain")\u{241E}\(block.content.trimmingCharacters(in: .whitespacesAndNewlines))"
    }
}
