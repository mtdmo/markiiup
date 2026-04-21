import Foundation
import XCTest
@testable import markiiupMac

final class MarkdownTableEditorTests: XCTestCase {
    func testActiveTableAndReplaceRoundTrip() throws {
        let markdown = """
        ## Changes

        | Name | Status |
        | --- | --- |
        | API | Draft |
        | DB | Review |
        """

        let table = try XCTUnwrap(MarkdownTableEditor.activeTable(in: markdown, lineNumber: 5))

        XCTAssertEqual(table.startLine, 3)
        XCTAssertEqual(table.endLine, 6)
        XCTAssertEqual(table.cellValue(row: 2, column: 0), "DB")

        let updated = table.updatingCell(row: 2, column: 1, value: "Done | Final")
        let rewritten = MarkdownTableEditor.replacingTable(in: markdown, with: updated)

        XCTAssertTrue(rewritten.contains("| DB | Done \\| Final |"))
        XCTAssertEqual(MarkdownReviewParser.analyze(rewritten).tables.first?.rows.last?[1], "Done | Final")
    }

    func testInsertTableIntoEmptyDocumentCreatesTemplate() {
        let insertion = MarkdownTableEditor.insertTable(
            in: "",
            selectedRange: NSRange(location: 0, length: 0),
            columns: 2,
            rows: 2
        )

        XCTAssertEqual(
            insertion.text,
            "| Column 1 | Column 2 |\n| --- | --- |\n|  |  |\n|  |  |\n"
        )
        XCTAssertEqual(insertion.selectionRange.location, 2)
        XCTAssertEqual(insertion.selectionRange.length, 8)
    }
}
