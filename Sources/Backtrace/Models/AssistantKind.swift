import Foundation

enum AssistantKind: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case codex
    case claude
    case grok
    case openCode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: "Codex"
        case .claude: "Claude Code"
        case .grok: "Grok Build"
        case .openCode: "OpenCode"
        }
    }

    var executableName: String {
        switch self {
        case .codex: "codex"
        case .claude: "claude"
        case .grok: "grok"
        case .openCode: "opencode"
        }
    }

    var symbolName: String {
        switch self {
        case .codex: "sparkles"
        case .claude: "sun.max.fill"
        case .grok: "bolt.fill"
        case .openCode: "terminal.fill"
        }
    }

    var iconAssetName: String {
        switch self {
        case .codex: "codex"
        case .claude: "claude"
        case .grok: "grok"
        case .openCode: "opencode"
        }
    }

    var colorToken: String {
        switch self {
        case .codex: "codex"
        case .claude: "claude"
        case .grok: "grok"
        case .openCode: "opencode"
        }
    }

    func defaultHistoryRoots(home: URL) -> [URL] {
        switch self {
        case .codex:
            let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"]
                .map { URL(fileURLWithPath: $0, isDirectory: true) }
                ?? home.appendingPathComponent(".codex", isDirectory: true)
            return [
                codexHome.appendingPathComponent("sessions", isDirectory: true),
                codexHome.appendingPathComponent("archived_sessions", isDirectory: true)
            ]
        case .claude:
            let claudeHome = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"]
                .map { URL(fileURLWithPath: $0, isDirectory: true) }
                ?? home.appendingPathComponent(".claude", isDirectory: true)
            return [claudeHome.appendingPathComponent("projects", isDirectory: true)]
        case .grok:
            return [home.appendingPathComponent(".grok/sessions", isDirectory: true)]
        case .openCode:
            return [home.appendingPathComponent(".local/share/opencode", isDirectory: true)]
        }
    }
}

struct AssistantInstallation: Identifiable, Hashable, Sendable {
    let kind: AssistantKind
    let executableURL: URL
    let version: String?

    var id: AssistantKind { kind }
}
