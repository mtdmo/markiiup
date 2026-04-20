import AppKit
import Foundation

@MainActor
enum DocumentOpenService {
    static func openDocument(at url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error {
                AppLogger.workspace.error("Failed to open \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
