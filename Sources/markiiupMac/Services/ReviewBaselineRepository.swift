import Foundation

enum ReviewBaselineRepository {
    private static let fileName = "review-baselines.json"

    static func loadSnapshot(for fileURL: URL) -> ReviewBaselineSnapshot? {
        let key = fileURL.standardizedFileURL.path
        return loadIndex()[key]
    }

    static func saveSnapshot(_ snapshot: ReviewBaselineSnapshot, for fileURL: URL) throws {
        var index = loadIndex()
        index[fileURL.standardizedFileURL.path] = snapshot
        try saveIndex(index)
    }

    static func removeSnapshot(for fileURL: URL) throws {
        var index = loadIndex()
        index.removeValue(forKey: fileURL.standardizedFileURL.path)
        try saveIndex(index)
    }

    private static func loadIndex() -> [String: ReviewBaselineSnapshot] {
        let url = storageURL()
        guard let data = try? Data(contentsOf: url) else {
            return [:]
        }

        return (try? JSONDecoder.reviewBaselineDecoder.decode([String: ReviewBaselineSnapshot].self, from: data)) ?? [:]
    }

    private static func saveIndex(_ index: [String: ReviewBaselineSnapshot]) throws {
        let url = storageURL()
        let directoryURL = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let data = try JSONEncoder.reviewBaselineEncoder.encode(index)
        try data.write(to: url, options: .atomic)
    }

    private static func storageURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return baseURL
            .appendingPathComponent("markiiup", isDirectory: true)
            .appendingPathComponent(fileName)
    }
}

private extension JSONEncoder {
    static var reviewBaselineEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var reviewBaselineDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
