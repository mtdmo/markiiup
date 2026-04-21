import Foundation

@MainActor
final class ReviewBaselineStore: ObservableObject {
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var snapshot: ReviewBaselineSnapshot?
    @Published private(set) var summary: ReviewBaselineSummary?
    @Published private(set) var storageError: String?

    private var baselineAnalysis: MarkdownAnalysis?

    func bind(fileURL: URL?, currentText: String, currentAnalysis: MarkdownAnalysis) {
        let standardizedURL = fileURL?.standardizedFileURL
        currentFileURL = standardizedURL
        storageError = nil

        guard let standardizedURL else {
            snapshot = nil
            baselineAnalysis = nil
            summary = nil
            return
        }

        snapshot = ReviewBaselineRepository.loadSnapshot(for: standardizedURL)
        baselineAnalysis = snapshot.map { MarkdownReviewParser.analyze($0.text) }
        refreshSummary(currentText: currentText, currentAnalysis: currentAnalysis)
    }

    func updateCurrentText(_ currentText: String, currentAnalysis: MarkdownAnalysis) {
        refreshSummary(currentText: currentText, currentAnalysis: currentAnalysis)
    }

    func captureBaseline(currentText: String, currentAnalysis: MarkdownAnalysis) {
        guard let currentFileURL else {
            return
        }

        let snapshot = ReviewBaselineSnapshot(fileURL: currentFileURL, text: currentText)

        do {
            try ReviewBaselineRepository.saveSnapshot(snapshot, for: currentFileURL)
            self.snapshot = snapshot
            baselineAnalysis = currentAnalysis
            storageError = nil
            refreshSummary(currentText: currentText, currentAnalysis: currentAnalysis)
            AppLogger.review.info("Captured review baseline for \(currentFileURL.path, privacy: .public)")
        } catch {
            storageError = error.localizedDescription
            AppLogger.review.error("Failed to capture review baseline for \(currentFileURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func clearBaseline(currentText: String, currentAnalysis: MarkdownAnalysis) {
        guard let currentFileURL else {
            return
        }

        do {
            try ReviewBaselineRepository.removeSnapshot(for: currentFileURL)
            snapshot = nil
            baselineAnalysis = nil
            summary = nil
            storageError = nil
            AppLogger.review.info("Cleared review baseline for \(currentFileURL.path, privacy: .public)")
        } catch {
            storageError = error.localizedDescription
            refreshSummary(currentText: currentText, currentAnalysis: currentAnalysis)
            AppLogger.review.error("Failed to clear review baseline for \(currentFileURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func refreshSummary(currentText: String, currentAnalysis: MarkdownAnalysis) {
        guard let snapshot, let baselineAnalysis else {
            summary = nil
            return
        }

        summary = ReviewBaselineComparison.compare(
            baseline: snapshot,
            baselineAnalysis: baselineAnalysis,
            currentText: currentText,
            currentAnalysis: currentAnalysis
        )
    }
}
