import Foundation

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var rootURL: URL?
    @Published private(set) var files: [WorkspaceFile] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var isWatchingWorkspace = false
    @Published private(set) var scanError: String?

    private let defaultsKey = "markiiup.workspace-root"
    private var refreshTask: Task<Void, Never>?
    private var needsRefreshAfterCurrentPass = false
    private var watcher: WorkspaceFileWatcher?

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
        scheduleRefresh(immediate: true)
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

    private func scheduleRefresh(immediate: Bool) {
        refreshTask?.cancel()

        if immediate {
            performRefresh()
            return
        }

        refreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self?.performRefresh()
            }
        }
    }

    private func performRefresh() {
        guard let rootURL else {
            files = []
            scanError = nil
            return
        }

        guard !isRefreshing else {
            needsRefreshAfterCurrentPass = true
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
                    self.finishRefreshIfNeeded()
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
                    self.finishRefreshIfNeeded()
                }
            }
        }
    }

    private func finishRefreshIfNeeded() {
        guard needsRefreshAfterCurrentPass else {
            return
        }

        needsRefreshAfterCurrentPass = false
        scheduleRefresh(immediate: false)
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
        startWatchingWorkspace(at: persistedURL)
        scheduleRefresh(immediate: true)
    }

    private func setRootURL(_ url: URL) {
        let standardizedURL = url.standardizedFileURL
        rootURL = standardizedURL
        UserDefaults.standard.set(standardizedURL.path, forKey: defaultsKey)
        startWatchingWorkspace(at: standardizedURL)
        scheduleRefresh(immediate: true)
    }

    private func startWatchingWorkspace(at url: URL) {
        watcher?.stop()
        watcher = WorkspaceFileWatcher(rootURL: url) { [weak self] changedPaths in
            Task { @MainActor in
                self?.handleWorkspaceChanges(changedPaths)
            }
        }
        watcher?.start()
        isWatchingWorkspace = true
        AppLogger.workspace.info("Watching workspace at \(url.path, privacy: .public)")
    }

    private func handleWorkspaceChanges(_ changedPaths: [String]) {
        guard changedPaths.contains(where: isRelevantWorkspacePath) else {
            return
        }

        AppLogger.workspace.debug("Workspace change detected; scheduling refresh")
        scheduleRefresh(immediate: false)
    }

    private func isRelevantWorkspacePath(_ path: String) -> Bool {
        let normalizedPath = path.replacingOccurrences(of: "\\", with: "/")
        let lowercasedPath = normalizedPath.lowercased()

        let ignoredSegments = ["/.build/", "/dist/", "/.git/", "/node_modules/"]
        guard !ignoredSegments.contains(where: { lowercasedPath.contains($0) }) else {
            return false
        }

        if WorkspacePathNormalizer.isMarkdownPath(path) {
            return true
        }

        return URL(fileURLWithPath: normalizedPath).pathExtension.isEmpty
    }
}
