import Foundation

enum SessionSourceFormat: String, Codable, Hashable, Sendable {
    case codexJSONL
    case claudeJSONL
    case grokJSON
    case openCodeLegacy
    case openCodeCLI
}

struct AssistantSession: Identifiable, Hashable, Sendable {
    let assistant: AssistantKind
    let sessionID: String
    let title: String
    let summary: String?
    let projectPath: String?
    let gitBranch: String?
    let model: String?
    let createdAt: Date?
    let updatedAt: Date
    let messageCount: Int?
    let fileSize: Int64
    let sourceURL: URL
    let sourceFormat: SessionSourceFormat
    let isArchived: Bool

    var id: String { "\(assistant.rawValue):\(sessionID)" }

    var projectName: String {
        guard let projectPath, !projectPath.isEmpty else { return "Unknown project" }
        return URL(fileURLWithPath: projectPath).lastPathComponent
    }

    var resumeCommand: String {
        let launch: String
        switch assistant {
        case .codex:
            if isArchived {
                launch = "codex unarchive \(sessionID.shellQuoted) && codex resume \(sessionID.shellQuoted)"
            } else {
                launch = "codex resume \(sessionID.shellQuoted)"
            }
        case .claude:
            launch = "claude --resume \(sessionID.shellQuoted)"
        case .grok:
            launch = "grok --resume \(sessionID.shellQuoted)"
        case .openCode:
            launch = "opencode --session \(sessionID.shellQuoted)"
        }

        guard let projectPath, !projectPath.isEmpty else { return launch }
        return "cd \(projectPath.shellQuoted) && \(launch)"
    }

    var searchableText: String {
        [
            title,
            summary,
            projectPath,
            gitBranch,
            model,
            sessionID,
            assistant.displayName
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .foldedForSearch
    }
}

enum TranscriptRole: String, Hashable, Sendable {
    case user
    case assistant
    case tool
    case system
}

struct TranscriptEntry: Identifiable, Hashable, Sendable {
    let id: String
    let role: TranscriptRole
    let text: String
    let timestamp: Date?
}

struct TranscriptPreview: Sendable {
    let entries: [TranscriptEntry]
    let isTruncated: Bool

    static let empty = TranscriptPreview(entries: [], isTruncated: false)
}

struct ScanResult: Sendable {
    let installations: [AssistantInstallation]
    let sessions: [AssistantSession]
    let warnings: [String]
}
