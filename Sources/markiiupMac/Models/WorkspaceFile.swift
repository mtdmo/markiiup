import Foundation

struct WorkspaceFile: Identifiable, Hashable, Sendable {
    let url: URL
    let relativePath: String
    let displayName: String
    let detail: String
    let normalizedRelativePath: String
    let normalizedRelativeStem: String
    let normalizedBaseName: String

    var id: String {
        url.standardizedFileURL.path
    }

    init(url: URL, rootURL: URL) {
        let standardizedURL = url.standardizedFileURL
        let standardizedRootURL = rootURL.standardizedFileURL
        let rootPath = standardizedRootURL.path.hasSuffix("/") ? standardizedRootURL.path : standardizedRootURL.path + "/"
        let fullPath = standardizedURL.path

        if fullPath.hasPrefix(rootPath) {
            relativePath = String(fullPath.dropFirst(rootPath.count))
        } else {
            relativePath = standardizedURL.lastPathComponent
        }

        let relativeDirectory = ((relativePath as NSString).deletingLastPathComponent)
        displayName = standardizedURL.deletingPathExtension().lastPathComponent
        detail = relativeDirectory == "." ? "Current folder" : relativeDirectory
        normalizedRelativePath = WorkspacePathNormalizer.normalizeLookupKey(relativePath)
        normalizedRelativeStem = WorkspacePathNormalizer.normalizedStemKey(relativePath)
        normalizedBaseName = WorkspacePathNormalizer.normalizedStemKey(displayName)
        self.url = standardizedURL
    }
}
