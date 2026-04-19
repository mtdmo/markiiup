import Foundation

enum WorkspaceLinkResolver {
    static func resolve(
        links: [LinkItem],
        currentFileURL: URL?,
        rootURL: URL?,
        files: [WorkspaceFile]
    ) -> [ResolvedWorkspaceLink] {
        guard !links.isEmpty, !files.isEmpty else {
            return []
        }

        let filesByPath = Dictionary(uniqueKeysWithValues: files.map {
            ($0.url.standardizedFileURL.path, $0)
        })
        let filesByRelativePath = Dictionary(uniqueKeysWithValues: files.map {
            ($0.normalizedRelativePath, $0)
        })
        let filesByRelativeStem = Dictionary(uniqueKeysWithValues: files.map {
            ($0.normalizedRelativeStem, $0)
        })
        let filesByBaseName = Dictionary(grouping: files, by: \.normalizedBaseName)

        var seenIDs = Set<String>()
        var resolvedLinks: [ResolvedWorkspaceLink] = []

        for link in links {
            guard let file = resolveFile(
                for: link,
                currentFileURL: currentFileURL,
                rootURL: rootURL,
                filesByPath: filesByPath,
                filesByRelativePath: filesByRelativePath,
                filesByRelativeStem: filesByRelativeStem,
                filesByBaseName: filesByBaseName
            ) else {
                continue
            }

            let resolvedLink = ResolvedWorkspaceLink(link: link, file: file)
            if seenIDs.insert(resolvedLink.id).inserted {
                resolvedLinks.append(resolvedLink)
            }
        }

        return resolvedLinks
    }

    private static func resolveFile(
        for link: LinkItem,
        currentFileURL: URL?,
        rootURL: URL?,
        filesByPath: [String: WorkspaceFile],
        filesByRelativePath: [String: WorkspaceFile],
        filesByRelativeStem: [String: WorkspaceFile],
        filesByBaseName: [String: [WorkspaceFile]]
    ) -> WorkspaceFile? {
        switch link.kind {
        case .wiki:
            return resolveWikiLink(
                destination: link.destination,
                filesByRelativeStem: filesByRelativeStem,
                filesByBaseName: filesByBaseName
            )
        case .markdown:
            return resolveMarkdownLink(
                destination: link.destination,
                currentFileURL: currentFileURL,
                rootURL: rootURL,
                filesByPath: filesByPath,
                filesByRelativePath: filesByRelativePath,
                filesByRelativeStem: filesByRelativeStem,
                filesByBaseName: filesByBaseName
            )
        }
    }

    private static func resolveWikiLink(
        destination: String,
        filesByRelativeStem: [String: WorkspaceFile],
        filesByBaseName: [String: [WorkspaceFile]]
    ) -> WorkspaceFile? {
        let stemKey = WorkspacePathNormalizer.normalizedStemKey(destination)
        if let match = filesByRelativeStem[stemKey] {
            return match
        }

        guard let candidates = filesByBaseName[stemKey], candidates.count == 1 else {
            return nil
        }

        return candidates.first
    }

    private static func resolveMarkdownLink(
        destination: String,
        currentFileURL: URL?,
        rootURL: URL?,
        filesByPath: [String: WorkspaceFile],
        filesByRelativePath: [String: WorkspaceFile],
        filesByRelativeStem: [String: WorkspaceFile],
        filesByBaseName: [String: [WorkspaceFile]]
    ) -> WorkspaceFile? {
        guard let localDestination = sanitizeLocalDestination(destination) else {
            return nil
        }

        for candidateURL in candidateURLs(
            for: localDestination,
            currentFileURL: currentFileURL,
            rootURL: rootURL
        ) {
            if let match = filesByPath[candidateURL.standardizedFileURL.path] {
                return match
            }
        }

        let normalizedPath = WorkspacePathNormalizer.normalizeLookupKey(localDestination)
        if let match = filesByRelativePath[normalizedPath] {
            return match
        }

        let normalizedStem = WorkspacePathNormalizer.normalizedStemKey(localDestination)
        if let match = filesByRelativeStem[normalizedStem] {
            return match
        }

        guard let candidates = filesByBaseName[normalizedStem], candidates.count == 1 else {
            return nil
        }

        return candidates.first
    }

    private static func sanitizeLocalDestination(_ destination: String) -> String? {
        let trimmed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else {
            return nil
        }

        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty {
            return nil
        }

        let withoutFragment = trimmed
            .split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? trimmed

        let withoutQuery = withoutFragment
            .split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? withoutFragment

        let normalized = withoutQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return nil
        }

        return normalized
    }

    private static func candidateURLs(
        for destination: String,
        currentFileURL: URL?,
        rootURL: URL?
    ) -> [URL] {
        var candidates: [URL] = []
        let cleanedDestination = destination.replacingOccurrences(of: "\\", with: "/")
        let destinationPath = cleanedDestination.hasPrefix("/") ? String(cleanedDestination.dropFirst()) : cleanedDestination

        if let currentFileURL {
            candidates.append(currentFileURL.deletingLastPathComponent().appendingPathComponent(destinationPath))
        }

        if let rootURL {
            candidates.append(rootURL.appendingPathComponent(destinationPath))
        }

        if !WorkspacePathNormalizer.isMarkdownPath(destinationPath) {
            var expandedCandidates: [URL] = []
            for candidate in candidates {
                expandedCandidates.append(candidate.appendingPathExtension("md"))
                expandedCandidates.append(candidate.appendingPathExtension("markdown"))
            }
            candidates.append(contentsOf: expandedCandidates)
        }

        return Array(Set(candidates.map(\.standardizedFileURL)))
    }
}
