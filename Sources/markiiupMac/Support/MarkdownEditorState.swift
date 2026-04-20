import Combine
import Foundation

enum EditorCommand: Equatable {
    case bold
    case italic
    case code
    case quote
    case checklist
    case heading(level: Int)
    case link
    case insertTable(columns: Int, rows: Int)
    case jumpToLine(Int)
}

struct EditorRequest: Identifiable, Equatable {
    let id = UUID()
    let command: EditorCommand
}

@MainActor
final class MarkdownEditorState: ObservableObject {
    @Published private(set) var currentLine = 1
    @Published private(set) var selectedRange = NSRange(location: 0, length: 0)
    @Published private(set) var hasSelection = false
    @Published var pendingRequest: EditorRequest?

    func send(_ command: EditorCommand) {
        pendingRequest = EditorRequest(command: command)
    }

    func markHandled(_ request: EditorRequest) {
        guard pendingRequest?.id == request.id else {
            return
        }

        pendingRequest = nil
    }

    func updateSelection(_ range: NSRange, in text: String) {
        let nsString = text as NSString
        let safeLocation = min(max(range.location, 0), nsString.length)
        let prefix = nsString.substring(to: safeLocation)
        let nextCurrentLine = max(1, prefix.components(separatedBy: "\n").count)
        let nextHasSelection = range.length > 0

        guard selectedRange != range || hasSelection != nextHasSelection || currentLine != nextCurrentLine else {
            return
        }

        selectedRange = range
        hasSelection = nextHasSelection
        currentLine = nextCurrentLine
    }
}
