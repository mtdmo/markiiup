import Foundation

enum WorkspaceScanner {
    private static let excludedDirectoryNames: Set<String> = [
        ".build",
        ".git",
        ".obsidian",
        "dist",
        "node_modules"
    ]

    static func scan(rootURL: URL) throws -> [WorkspaceFile] {
        let standardizedRootURL = rootURL.standardizedFileURL
        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .nameKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: standardizedRootURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { url, error in
                AppLogger.workspace.error("Workspace scan skipped \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return true
            }
        ) else {
            return []
        }

        var files: [WorkspaceFile] = []

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)

            if resourceValues.isDirectory == true {
                let name = (resourceValues.name ?? fileURL.lastPathComponent).lowercased()
                if excludedDirectoryNames.contains(name) {
                    enumerator.skipDescendants()
                }
                continue
            }

            guard resourceValues.isRegularFile == true else {
                continue
            }

            guard WorkspacePathNormalizer.isMarkdownPath(fileURL.path) else {
                continue
            }

            files.append(WorkspaceFile(url: fileURL, rootURL: standardizedRootURL))
        }

        return files.sorted {
            $0.relativePath.localizedCaseInsensitiveCompare($1.relativePath) == .orderedAscending
        }
    }
}
