import Foundation

struct ResolvedWorkspaceLink: Identifiable, Hashable {
    let link: LinkItem
    let file: WorkspaceFile

    var id: String {
        "\(link.id)-\(file.id)"
    }
}
