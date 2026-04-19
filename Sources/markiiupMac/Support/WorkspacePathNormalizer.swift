import Foundation

enum WorkspacePathNormalizer {
    static func normalizeLookupKey(_ value: String) -> String {
        let decoded = value.removingPercentEncoding ?? value
        let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
        let slashNormalized = trimmed.replacingOccurrences(of: "\\", with: "/")
        let withoutLeadingDot = slashNormalized.replacingOccurrences(of: "./", with: "", options: .anchored)
        let components = withoutLeadingDot
            .split(separator: "/")
            .map { component in
                component
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .lowercased()
            }
            .filter { !$0.isEmpty }

        return components.joined(separator: "/")
    }

    static func normalizedStemKey(_ value: String) -> String {
        let key = normalizeLookupKey(value)
        return (key as NSString).deletingPathExtension
    }

    static func isMarkdownPath(_ value: String) -> Bool {
        let ext = (value as NSString).pathExtension.lowercased()
        return ext == "md" || ext == "markdown"
    }
}
