import Foundation

struct ReviewBaselineSummary: Equatable {
    let capturedAt: Date
    let addedLineCount: Int
    let removedLineCount: Int
    let addedHeadingCount: Int
    let removedHeadingCount: Int
    let addedTableCount: Int
    let removedTableCount: Int
    let addedSQLBlockCount: Int
    let removedSQLBlockCount: Int
    let openTaskDelta: Int
    let completedTaskDelta: Int
    let linkDelta: Int

    var hasChanges: Bool {
        addedLineCount > 0 ||
        removedLineCount > 0 ||
        addedHeadingCount > 0 ||
        removedHeadingCount > 0 ||
        addedTableCount > 0 ||
        removedTableCount > 0 ||
        addedSQLBlockCount > 0 ||
        removedSQLBlockCount > 0 ||
        openTaskDelta != 0 ||
        completedTaskDelta != 0 ||
        linkDelta != 0
    }

    var compactLabel: String {
        if !hasChanges {
            return "No changes since the current review baseline."
        }

        var parts = ["+\(addedLineCount)/-\(removedLineCount) lines"]

        if addedTableCount > 0 || removedTableCount > 0 {
            parts.append("tables +\(addedTableCount)/-\(removedTableCount)")
        }

        if addedSQLBlockCount > 0 || removedSQLBlockCount > 0 {
            parts.append("SQL +\(addedSQLBlockCount)/-\(removedSQLBlockCount)")
        }

        if openTaskDelta != 0 {
            parts.append("open tasks \(Self.signed(openTaskDelta))")
        }

        return "Since baseline: " + parts.joined(separator: " · ")
    }

    static func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }
}
