import Foundation

enum SidebarSelection: Hashable, Sendable {
    case all
    case assistant(AssistantKind)
    case tag(UUID)
    case trackedFolder(String)
    case claudeConfigDirectory(String)
}

struct TrackedFolder: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let path: String

    init(id: UUID = UUID(), path: String) {
        self.id = id
        self.path = path
    }

    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
