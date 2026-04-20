import Foundation

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var rootURL: URL?
    @Published private(set) var files: [WorkspaceFile] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var scanError: String?

    private let defaultsKey = "markiiup.workspace-root"

    init() {
        loadPersistedWorkspace()
    }

    func primeWorkspace(for currentFileURL: URL?) {
        guard rootURL == nil, let currentFileURL else {
            return
        }

        setRootURL(currentFileURL.deletingLastPathComponent())
    }

    func chooseFolder() {
        if let pickedURL = WorkspaceFolderPicker.pickFolder(initialDirectory: rootURL) {
            setRootURL(pickedURL)
        }
    }

    func refresh() {
        guard let rootURL else {
            files = []
            scanError = nil
            return
        }

        isRefreshing = true
        scanError = nil
        let workspaceRootURL = rootURL.standardizedFileURL

        Task.detached(priority: .userInitiated) {
            do {
                let scannedFiles = try WorkspaceScanner.scan(rootURL: workspaceRootURL)
                await MainActor.run {
                    guard self.rootURL?.standardizedFileURL == workspaceRootURL else {
                        return
                    }

                    self.files = scannedFiles
                    self.isRefreshing = false
                    AppLogger.workspace.info("Loaded \(scannedFiles.count, privacy: .public) markdown files from \(workspaceRootURL.path, privacy: .public)")
                }
            } catch {
                await MainActor.run {
                    guard self.rootURL?.standardizedFileURL == workspaceRootURL else {
                        return
                    }

                    self.files = []
                    self.isRefreshing = false
                    self.scanError = error.localizedDescription
                    AppLogger.workspace.error("Workspace scan failed for \(workspaceRootURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    func open(_ file: WorkspaceFile) {
        DocumentOpenService.openDocument(at: file.url)
    }

    func relatedFiles(for analysis: MarkdownAnalysis, currentFileURL: URL?) -> [ResolvedWorkspaceLink] {
        WorkspaceLinkResolver.resolve(
            links: analysis.links,
            currentFileURL: currentFileURL,
            rootURL: rootURL,
            files: files
        )
    }

    func isCurrentDocument(_ file: WorkspaceFile, currentFileURL: URL?) -> Bool {
        guard let currentFileURL else {
            return false
        }

        return file.url.standardizedFileURL == currentFileURL.standardizedFileURL
    }

    private func loadPersistedWorkspace() {
        guard let path = UserDefaults.standard.string(forKey: defaultsKey) else {
            return
        }

        let persistedURL = URL(fileURLWithPath: path).standardizedFileURL
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: persistedURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
            return
        }

        rootURL = persistedURL
        refresh()
    }

    private func setRootURL(_ url: URL) {
        let standardizedURL = url.standardizedFileURL
        rootURL = standardizedURL
        UserDefaults.standard.set(standardizedURL.path, forKey: defaultsKey)
        refresh()
    }
}
