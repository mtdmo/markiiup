import AppKit
import SwiftUI

struct ReviewWorkspaceView: View {
    @Binding var document: MarkdownDocument
    let analysis: MarkdownAnalysis
    @Binding var mode: WorkspaceMode
    @ObservedObject var editorState: MarkdownEditorState

    var body: some View {
        EditorPaneView(
            text: $document.text,
            editorState: editorState,
            metrics: analysis.metrics,
            mode: mode
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
