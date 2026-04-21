import Foundation

struct ReviewBaselineSnapshot: Codable, Equatable {
    let filePath: String
    let capturedAt: Date
    let text: String

    init(fileURL: URL, capturedAt: Date = .now, text: String) {
        self.filePath = fileURL.standardizedFileURL.path
        self.capturedAt = capturedAt
        self.text = text
    }
}
