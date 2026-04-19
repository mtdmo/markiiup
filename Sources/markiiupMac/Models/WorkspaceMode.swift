import Foundation

enum WorkspaceMode: String, CaseIterable, Identifiable {
    case document
    case markdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .document:
            return "Document"
        case .markdown:
            return "Markdown"
        }
    }
}
