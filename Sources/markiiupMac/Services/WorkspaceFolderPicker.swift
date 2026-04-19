import AppKit
import Foundation

@MainActor
enum WorkspaceFolderPicker {
    static func pickFolder(initialDirectory: URL?) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose Markdown Workspace"
        panel.prompt = "Choose Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.directoryURL = initialDirectory

        return panel.runModal() == .OK ? panel.url?.standardizedFileURL : nil
    }
}
