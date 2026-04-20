import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    let currentFileURL: URL?
    @StateObject private var editorState = MarkdownEditorState()
    @StateObject private var workspaceStore = WorkspaceStore()
    @State private var mode: WorkspaceMode = .document
    @State private var sidebarQuery = ""

    private var analysis: MarkdownAnalysis {
        MarkdownReviewParser.analyze(document.text)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                analysis: analysis,
                workspaceStore: workspaceStore,
                currentFileURL: currentFileURL,
                query: $sidebarQuery,
                currentLine: editorState.currentLine,
                jumpToLine: { lineNumber in
                    editorState.send(.jumpToLine(lineNumber))
                }
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        } detail: {
            ReviewWorkspaceView(
                document: $document,
                analysis: analysis,
                mode: $mode,
                editorState: editorState
            )
        }
        .focusedSceneValue(
            \.markdownEditorActionHandler,
             MarkdownEditorActionHandler(send: { command in
                 editorState.send(command)
             })
        )
        .frame(minWidth: 1100, minHeight: 720)
        .onAppear {
            workspaceStore.primeWorkspace(for: currentFileURL)
        }
        .onChange(of: currentFileURL) { _, newValue in
            workspaceStore.primeWorkspace(for: newValue)
        }
        .toolbarRole(.editor)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    workspaceStore.chooseFolder()
                } label: {
                    Label("Choose Folder", systemImage: "folder")
                }
                .help("Choose the Markdown workspace shown in the sidebar")

                Button {
                    workspaceStore.refresh()
                } label: {
                    Label("Refresh Workspace", systemImage: "arrow.clockwise")
                }
                .help("Rescan the workspace folder for Markdown files")
                .disabled(workspaceStore.rootURL == nil || workspaceStore.isRefreshing)
            }

            ToolbarItem(placement: .principal) {
                Picker("Workspace", selection: $mode) {
                    ForEach(WorkspaceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Heading 1") { editorState.send(.heading(level: 1)) }
                    Button("Heading 2") { editorState.send(.heading(level: 2)) }
                    Button("Heading 3") { editorState.send(.heading(level: 3)) }
                } label: {
                    Label("Heading", systemImage: "textformat.size")
                }

                Button {
                    editorState.send(.bold)
                } label: {
                    Image(systemName: "bold")
                }
                .help("Apply bold formatting")

                Button {
                    editorState.send(.italic)
                } label: {
                    Image(systemName: "italic")
                }
                .help("Apply italic formatting")

                Button {
                    editorState.send(.code)
                } label: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                .help("Apply inline code formatting")

                Button {
                    editorState.send(.checklist)
                } label: {
                    Image(systemName: "checklist.unchecked")
                }
                .help("Insert or extend a checklist item")

                Button {
                    editorState.send(.quote)
                } label: {
                    Image(systemName: "text.quote")
                }
                .help("Turn the current line into a quote block")

                Button {
                    editorState.send(.link)
                } label: {
                    Image(systemName: "link")
                }
                .help("Insert a link")

                Menu {
                    Button("Insert 2 x 2 Table") {
                        editorState.send(.insertTable(columns: 2, rows: 2))
                    }

                    Button("Insert 3 x 3 Table") {
                        editorState.send(.insertTable(columns: 3, rows: 3))
                    }

                    Button("Insert 4 x 3 Table") {
                        editorState.send(.insertTable(columns: 4, rows: 3))
                    }
                } label: {
                    Image(systemName: "tablecells")
                }
                .help("Insert a Markdown table")
            }
        }
    }
}
