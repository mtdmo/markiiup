import AppKit
import SwiftUI

struct ReviewWorkspaceView: View {
    @Binding var document: MarkdownDocument
    let analysis: MarkdownAnalysis
    let reviewSummary: ReviewBaselineSummary?
    @Binding var mode: WorkspaceMode
    @ObservedObject var editorState: MarkdownEditorState

    var body: some View {
        EditorPaneView(
            text: $document.text,
            editorState: editorState,
            metrics: analysis.metrics,
            reviewSummary: reviewSummary,
            mode: mode
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
