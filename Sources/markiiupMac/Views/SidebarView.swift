import SwiftUI

struct SidebarView: View {
    let analysis: MarkdownAnalysis
    @ObservedObject var reviewBaselineStore: ReviewBaselineStore
    @ObservedObject var workspaceStore: WorkspaceStore
    let currentFileURL: URL?
    @Binding var query: String
    let currentLine: Int
    let captureBaseline: () -> Void
    let clearBaseline: () -> Void
    let jumpToLine: (Int) -> Void

    private let maxWorkspaceRows = 100

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    MarkiiupBrandHeaderView()
                    filterField
                }
            }

            Section("Workspace") {
                if let rootURL = workspaceStore.rootURL {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rootURL.lastPathComponent)
                            .font(.body.weight(.medium))
                            .lineLimit(1)
                        Text(rootURL.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack {
                        Text("\(workspaceStore.files.count) Markdown files")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if workspaceStore.isWatchingWorkspace {
                            Text("Live updates on")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.accentColor.opacity(0.10))
                                )
                        }

                        Spacer()

                        if workspaceStore.isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    HStack(spacing: 8) {
                        Button("Choose Folder") {
                            workspaceStore.chooseFolder()
                        }

                        Button("Refresh") {
                            workspaceStore.refresh()
                        }
                        .disabled(workspaceStore.isRefreshing)
                    }

                    if let scanError = workspaceStore.scanError {
                        Text(scanError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else {
                    Text("Choose a folder to browse Markdown files and follow related links from the current document.")
                        .foregroundStyle(.secondary)

                    Button("Choose Folder") {
                        workspaceStore.chooseFolder()
                    }
                }
            }

            Section("Review Baseline") {
                if currentFileURL == nil {
                    Text("Save the document to capture a reusable review baseline.")
                        .foregroundStyle(.secondary)
                } else {
                    reviewBaselineSection
                }
            }

            Section("Open Tasks") {
                if filteredOpenTasks.isEmpty {
                    Text(query.isEmpty ? "No open tasks" : "No matching tasks")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredOpenTasks) { task in
                        taskRow(task)
                    }
                }
            }

            Section("Related Files") {
                if filteredRelatedFiles.isEmpty {
                    Text(query.isEmpty ? "No related workspace files found" : "No matching related files")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredRelatedFiles) { relatedFile in
                        Button {
                            workspaceStore.open(relatedFile.file)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(relatedFile.file.displayName)
                                        .lineLimit(1)
                                    Text("\(relatedFile.file.relativePath) · \(relatedFile.link.kind.rawValue) · L\(relatedFile.link.lineNumber)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Tags") {
                if filteredTags.isEmpty {
                    Text(query.isEmpty ? "No tags detected" : "No matching tags")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredTags) { tag in
                        Button {
                            jumpToLine(tag.firstLine)
                        } label: {
                            HStack {
                                Text("#\(tag.name)")
                                    .lineLimit(1)
                                Spacer()
                                Text("\(tag.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Links") {
                if filteredLinks.isEmpty {
                    Text(query.isEmpty ? "No links detected" : "No matching links")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredLinks) { link in
                        Button {
                            jumpToLine(link.lineNumber)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: link.kind == .wiki ? "link.circle" : "link")
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(link.label)
                                        .lineLimit(1)
                                    Text(link.destination)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text("L\(link.lineNumber)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Outline") {
                if filteredHeadings.isEmpty {
                    Text(query.isEmpty ? "No headings yet" : "No matching headings")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredHeadings) { item in
                        Button {
                            jumpToLine(item.lineNumber)
                        } label: {
                            HStack(spacing: 10) {
                                Text(item.title)
                                    .lineLimit(1)
                                    .padding(.leading, CGFloat(max(item.level - 1, 0)) * 10)

                                Spacer()

                                Text("L\(item.lineNumber)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .fontWeight(item.lineNumber == currentLine ? .semibold : .regular)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Workspace Files") {
                if filteredWorkspaceFiles.isEmpty {
                    Text(query.isEmpty ? "No Markdown files in the selected folder" : "No matching files")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(filteredWorkspaceFiles.prefix(maxWorkspaceRows))) { file in
                        workspaceFileRow(file)
                    }

                    if filteredWorkspaceFiles.count > maxWorkspaceRows {
                        Text("Showing first \(maxWorkspaceRows) matches")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var filterField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Filter sidebar items", text: $query)
                .textFieldStyle(.plain)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    @ViewBuilder
    private var reviewBaselineSection: some View {
        if let summary = reviewBaselineStore.summary {
            VStack(alignment: .leading, spacing: 10) {
                Text("Captured \(summary.capturedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if summary.hasChanges {
                    baselineMetricRow("Lines", value: "+\(summary.addedLineCount) / -\(summary.removedLineCount)")

                    if summary.addedTableCount > 0 || summary.removedTableCount > 0 {
                        baselineMetricRow("Tables", value: "+\(summary.addedTableCount) / -\(summary.removedTableCount)")
                    }

                    if summary.addedSQLBlockCount > 0 || summary.removedSQLBlockCount > 0 {
                        baselineMetricRow("SQL", value: "+\(summary.addedSQLBlockCount) / -\(summary.removedSQLBlockCount)")
                    }

                    if summary.openTaskDelta != 0 || summary.completedTaskDelta != 0 {
                        baselineMetricRow(
                            "Tasks",
                            value: "open \(ReviewBaselineSummary.signed(summary.openTaskDelta)), done \(ReviewBaselineSummary.signed(summary.completedTaskDelta))"
                        )
                    }

                    if summary.linkDelta != 0 {
                        baselineMetricRow("Links", value: ReviewBaselineSummary.signed(summary.linkDelta))
                    }
                } else {
                    Text("No document changes detected since the current review baseline.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Button("Update Baseline") {
                        captureBaseline()
                    }

                    Button("Clear") {
                        clearBaseline()
                    }
                    .foregroundStyle(.red)
                }
            }

            if let storageError = reviewBaselineStore.storageError {
                Text(storageError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } else {
            Text("Capture the current file as a baseline, then use the canvas to see what changed since that review point.")
                .foregroundStyle(.secondary)

            Button("Capture Baseline") {
                captureBaseline()
            }

            if let storageError = reviewBaselineStore.storageError {
                Text(storageError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var filteredRelatedFiles: [ResolvedWorkspaceLink] {
        workspaceStore.relatedFiles(for: analysis, currentFileURL: currentFileURL)
            .filter { item in
                matchesQuery(item.file.displayName) ||
                matchesQuery(item.file.relativePath) ||
                matchesQuery(item.link.destination)
            }
    }

    private var filteredWorkspaceFiles: [WorkspaceFile] {
        workspaceStore.files.filter { file in
            matchesQuery(file.displayName) || matchesQuery(file.relativePath)
        }
    }

    private var filteredHeadings: [OutlineItem] {
        analysis.headings.filter { matchesQuery($0.title) }
    }

    private var filteredOpenTasks: [TaskItem] {
        analysis.openTasks.filter { matchesQuery($0.title) }
    }

    private var filteredLinks: [LinkItem] {
        analysis.links.filter { matchesQuery($0.label) || matchesQuery($0.destination) }
    }

    private var filteredTags: [TagItem] {
        analysis.tags.filter { matchesQuery($0.name) }
    }

    private func matchesQuery(_ value: String) -> Bool {
        query.isEmpty || value.localizedCaseInsensitiveContains(query)
    }

    private func taskRow(_ task: TaskItem) -> some View {
        Button {
            jumpToLine(task.lineNumber)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.completed ? .green : .secondary)

                Text(task.title)
                    .lineLimit(1)

                Spacer()

                Text("L\(task.lineNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .buttonStyle(.plain)
    }

    private func workspaceFileRow(_ file: WorkspaceFile) -> some View {
        let isCurrentDocument = workspaceStore.isCurrentDocument(file, currentFileURL: currentFileURL)

        return Button {
            workspaceStore.open(file)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isCurrentDocument ? "checkmark.circle.fill" : "doc.text")
                    .foregroundStyle(isCurrentDocument ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.displayName)
                        .lineLimit(1)
                    Text(file.relativePath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .disabled(isCurrentDocument)
    }

    private func baselineMetricRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }
}
