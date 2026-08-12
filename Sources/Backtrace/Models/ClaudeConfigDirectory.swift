import Foundation

/// One Claude Code configuration directory, the folder `CLAUDE_CONFIG_DIR`
/// points at. Claude Code only ever uses one at a time, so people who keep
/// work and personal setups apart end up with several of them on disk.
struct ClaudeConfigDirectory: Identifiable, Hashable, Sendable {
    enum Source: String, Hashable, Sendable {
        case defaultLocation
        case environment
        case added

        var displayName: String {
            switch self {
            case .defaultLocation: "Default"
            case .environment: "CLAUDE_CONFIG_DIR"
            case .added: "Added"
            }
        }
    }

    let url: URL
    let source: Source
    let isDefault: Bool

    var id: String { url.path }

    var projectsRoot: URL {
        url.appendingPathComponent("projects", isDirectory: true)
    }

    /// An added directory can be renamed or deleted after the fact, so its
    /// presence is worth reporting rather than showing an empty session count.
    var exists: Bool {
        var isDirectory: ObjCBool = false
        let found = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return found && isDirectory.boolValue
    }

    /// Whether Claude Code has ever written sessions here. A config directory
    /// only grows a `projects` folder once it has been used.
    var hasProjects: Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: projectsRoot.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    /// Short label for the sidebar and badges: `.claude` reads as "Default",
    /// `.claude-signit` as "signit", and anything else keeps its folder name.
    var name: String {
        if isDefault { return "Default" }
        let component = url.lastPathComponent
        if component.hasPrefix(".claude-") {
            return String(component.dropFirst(".claude-".count))
        }
        if component.hasPrefix("."), component.count > 1 {
            return String(component.dropFirst())
        }
        return component
    }
}

/// The verdict on a path someone typed into the add-directory field.
enum ClaudeConfigDirectoryValidation: Equatable {
    case empty
    /// Cannot be added. The text says why.
    case rejected(String)
    /// Can be added, at the resolved path. A note flags anything surprising.
    case accepted(URL, note: String?)

    var url: URL? {
        guard case .accepted(let url, _) = self else { return nil }
        return url
    }

    var message: String? {
        switch self {
        case .empty: nil
        case .rejected(let reason): reason
        case .accepted(_, let note): note
        }
    }

    var isRejected: Bool {
        if case .rejected = self { return true }
        return false
    }
}
