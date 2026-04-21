import XCTest
@testable import markiiupMac

final class MarkdownReviewParserTests: XCTestCase {
    func testAnalyzeCapturesReviewStructureAndSQL() throws {
        let markdown = """
        ---
        title: Example Spec
        owner: Platform
        ---

        # Rollout Plan

        - [ ] Review migration plan
        - [x] Confirm rollback
        See [Guide](guide.md) and [[Runbook]]
        Tags: #release #backend

        | Change | Owner |
        | --- | --- |
        | Add column | Data |

        ```sql
        select *
        from users;
        ```
        """

        let analysis = MarkdownReviewParser.analyze(markdown)

        XCTAssertEqual(analysis.frontMatter.map(\.key), ["title", "owner"])
        XCTAssertEqual(analysis.headings.map(\.title), ["Rollout Plan"])
        XCTAssertEqual(analysis.metrics.openTaskCount, 1)
        XCTAssertEqual(analysis.metrics.completedTaskCount, 1)
        XCTAssertEqual(analysis.links.count, 2)
        XCTAssertEqual(Set(analysis.tags.map(\.name)), Set(["release", "backend"]))
        XCTAssertEqual(analysis.tables.count, 1)
        XCTAssertEqual(analysis.tables.first?.headers, ["Change", "Owner"])
        XCTAssertEqual(analysis.tables.first?.rows, [["Add column", "Data"]])
        XCTAssertEqual(analysis.metrics.sqlBlockCount, 1)
        XCTAssertEqual(analysis.sqlCodeBlocks.first?.content, "select *\nfrom users;")
    }

    func testAnalyzeSkipsTasksTagsAndLinksInsideCodeFences() throws {
        let markdown = """
        ```md
        - [ ] hidden task
        #hidden
        [Ignore](ignore.md)
        ```

        - [ ] visible task
        #visible
        """

        let analysis = MarkdownReviewParser.analyze(markdown)

        XCTAssertEqual(analysis.tasks.map(\.title), ["visible task"])
        XCTAssertEqual(analysis.links.count, 0)
        XCTAssertEqual(analysis.tags.map(\.name), ["visible"])
        XCTAssertEqual(analysis.metrics.codeBlockCount, 1)
    }
}
