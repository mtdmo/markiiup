import Foundation
import OSLog
import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    static let readableContentTypes: [UTType] = [
        UTType(filenameExtension: "md") ?? .plainText,
        UTType(filenameExtension: "markdown") ?? .plainText,
        .plainText
    ]

    var text: String

    init(text: String = MarkdownTemplates.newDocument) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) {
            self.text = text
            AppLogger.document.info("Opened markdown document with \(text.count, privacy: .public) characters")
        } else {
            self.text = MarkdownTemplates.newDocument
            AppLogger.document.warning("Fell back to an empty document because the source file could not be decoded")
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        AppLogger.document.info("Writing markdown document with \(text.count, privacy: .public) characters")
        return .init(regularFileWithContents: Data(text.utf8))
    }
}

private enum MarkdownTemplates {
    static let newDocument = """
    # Untitled

    Start writing in the document canvas. The app keeps the Markdown file canonical while presenting it like a formatted document.
    """
}
