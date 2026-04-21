import Foundation
import XCTest
@testable import markiiupMac

final class ReviewBaselineComparisonTests: XCTestCase {
    func testCompareCapturesStructuralReviewDeltas() throws {
        let baselineText = """
        # Spec

        - [ ] Review API

        | Name | Status |
        | --- | --- |
        | DB | Draft |

        ```sql
        select * from users;
        ```
        """

        let currentText = """
        # Spec

        ## Approval
        - [ ] Review API
        - [x] Sign off

        | Name | Status |
        | --- | --- |
        | DB | Final |
        | API | Draft |

        ```sql
        select id
        from users;
        ```
        """

        let baseline = ReviewBaselineSnapshot(
            fileURL: URL(fileURLWithPath: "/tmp/spec.md"),
            capturedAt: Date(timeIntervalSince1970: 1_700_000_000),
            text: baselineText
        )

        let summary = ReviewBaselineComparison.compare(
            baseline: baseline,
            baselineAnalysis: MarkdownReviewParser.analyze(baselineText),
            currentText: currentText,
            currentAnalysis: MarkdownReviewParser.analyze(currentText)
        )

        XCTAssertTrue(summary.hasChanges)
        XCTAssertEqual(summary.addedHeadingCount, 1)
        XCTAssertEqual(summary.removedHeadingCount, 0)
        XCTAssertEqual(summary.addedTableCount, 1)
        XCTAssertEqual(summary.removedTableCount, 1)
        XCTAssertEqual(summary.addedSQLBlockCount, 1)
        XCTAssertEqual(summary.removedSQLBlockCount, 1)
        XCTAssertEqual(summary.openTaskDelta, 0)
        XCTAssertEqual(summary.completedTaskDelta, 1)
        XCTAssertGreaterThan(summary.addedLineCount, 0)
    }

    func testCompareRecognizesUnchangedBaseline() throws {
        let text = """
        # Spec

        - [ ] Review API
        """

        let baseline = ReviewBaselineSnapshot(fileURL: URL(fileURLWithPath: "/tmp/spec.md"), text: text)
        let analysis = MarkdownReviewParser.analyze(text)

        let summary = ReviewBaselineComparison.compare(
            baseline: baseline,
            baselineAnalysis: analysis,
            currentText: text,
            currentAnalysis: analysis
        )

        XCTAssertFalse(summary.hasChanges)
        XCTAssertEqual(summary.compactLabel, "No changes since the current review baseline.")
    }
}
