import Foundation

struct DocumentMetrics {
    let wordCount: Int
    let characterCount: Int
    let lineCount: Int
    let readingMinutes: Int
    let headingCount: Int
    let openTaskCount: Int
    let completedTaskCount: Int
    let linkCount: Int
    let tagCount: Int
    let frontMatterKeyCount: Int
    let tableCount: Int
    let codeBlockCount: Int
    let sqlBlockCount: Int

    var readingLabel: String {
        readingMinutes == 1 ? "1 min" : "\(readingMinutes) min"
    }
}

struct FrontMatterEntry: Identifiable, Hashable {
    let key: String
    let value: String

    var id: String { key }
}

struct OutlineItem: Identifiable, Hashable {
    let title: String
    let level: Int
    let lineNumber: Int

    var id: String { "\(lineNumber)-\(title)" }
}

struct TaskItem: Identifiable, Hashable {
    let title: String
    let completed: Bool
    let lineNumber: Int

    var id: String { "\(lineNumber)-\(title)" }
}

enum LinkKind: String, Hashable {
    case markdown = "Markdown"
    case wiki = "Wiki"
}

struct LinkItem: Identifiable, Hashable {
    let label: String
    let destination: String
    let lineNumber: Int
    let kind: LinkKind

    var id: String { "\(lineNumber)-\(kind.rawValue)-\(destination)" }
}

struct TagItem: Identifiable, Hashable {
    let name: String
    let count: Int
    let firstLine: Int

    var id: String { name }
}

struct TableBlock: Identifiable, Hashable {
    let headers: [String]
    let rows: [[String]]
    let startLine: Int
    let endLine: Int

    var id: String { "\(startLine)-\(endLine)" }

    var columnCount: Int {
        max(headers.count, rows.map(\.count).max() ?? 0)
    }

    var rowCount: Int {
        rows.count
    }

    var searchableText: String {
        ([headers] + rows)
            .flatMap { $0 }
            .joined(separator: " ")
    }
}

struct CodeBlockItem: Identifiable, Hashable {
    let language: String?
    let content: String
    let startLine: Int
    let endLine: Int

    var id: String { "\(startLine)-\(endLine)-\(language ?? "plain")" }

    var normalizedLanguage: String? {
        language?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    var displayLanguage: String {
        guard let normalizedLanguage, !normalizedLanguage.isEmpty else {
            return "Code"
        }

        return normalizedLanguage.uppercased()
    }

    var isSQL: Bool {
        guard let normalizedLanguage else {
            return false
        }

        return ["sql", "psql", "postgresql", "mysql", "sqlite", "snowflake", "bigquery", "redshift"]
            .contains(normalizedLanguage)
    }

    var preview: String {
        let lines = content
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if lines.isEmpty {
            return "Empty code block"
        }

        return lines.prefix(4).joined(separator: "\n")
    }
}

struct MarkdownAnalysis {
    let metrics: DocumentMetrics
    let frontMatter: [FrontMatterEntry]
    let headings: [OutlineItem]
    let tasks: [TaskItem]
    let links: [LinkItem]
    let tags: [TagItem]
    let tables: [TableBlock]
    let codeBlocks: [CodeBlockItem]

    var openTasks: [TaskItem] {
        tasks.filter { !$0.completed }
    }

    var completedTasks: [TaskItem] {
        tasks.filter(\.completed)
    }

    var sqlCodeBlocks: [CodeBlockItem] {
        codeBlocks.filter(\.isSQL)
    }

    var otherCodeBlocks: [CodeBlockItem] {
        codeBlocks.filter { !$0.isSQL }
    }
}
