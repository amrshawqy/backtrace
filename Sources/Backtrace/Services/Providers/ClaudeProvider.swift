import Foundation

struct ClaudeProvider: SessionProvider {
    let assistant = AssistantKind.claude
    let roots: [URL]

    init(home: URL) {
        roots = AssistantKind.claude.defaultHistoryRoots(home: home)
    }

    init(roots: [URL]) {
        self.roots = roots
    }

    func sessions() throws -> [AssistantSession] {
        roots.flatMap { root in
            FileMetadata.files(
                below: root,
                extensions: ["jsonl"],
                excludingPathComponents: ["subagents"]
            ).compactMap { try? session(at: $0) }
        }
    }

    private func session(at url: URL) throws -> AssistantSession? {
        let objects = try JSONLReader.sampledObjects(at: url)
        let messageObjects = objects.filter {
            let type = $0["type"] as? String
            return type == "user" || type == "assistant"
        }
        guard let firstMessage = messageObjects.first else { return nil }

        let id = JSONValue.string(firstMessage, keys: ["sessionId"])
            ?? url.deletingPathExtension().lastPathComponent
        let prompt = SessionText.firstPrompt(in: objects, assistant: .claude)
        let customTitle = objects.reversed().lazy.compactMap { object -> String? in
            guard (object["type"] as? String) == "custom-title" else { return nil }
            return object["customTitle"] as? String
        }.first
        let aiTitle = objects.reversed().lazy.compactMap { object -> String? in
            guard (object["type"] as? String) == "ai-title" else { return nil }
            return object["aiTitle"] as? String
        }.first
        let projectPath = messageObjects.lazy.compactMap { $0["cwd"] as? String }.first
        let branch = messageObjects.lazy.compactMap { $0["gitBranch"] as? String }.first
        let model = messageObjects.lazy.compactMap { object -> String? in
            guard let message = object["message"] as? [String: Any] else { return nil }
            return message["model"] as? String
        }.first
        let timestamps = messageObjects.compactMap { FlexibleDateParser.parse($0["timestamp"]) }
        let file = FileMetadata.values(for: url)

        let title = customTitle
            ?? aiTitle
            ?? prompt?.clipped(to: 92)
            ?? projectPath.map { "\(URL(fileURLWithPath: $0).lastPathComponent) session" }
            ?? "Untitled Claude session"

        return AssistantSession(
            assistant: .claude,
            sessionID: id,
            title: title,
            summary: prompt?.clipped(to: 260),
            projectPath: projectPath,
            gitBranch: branch,
            model: model,
            createdAt: timestamps.min(),
            updatedAt: max(file.modified, timestamps.max() ?? .distantPast),
            messageCount: nil,
            fileSize: file.size,
            sourceURL: url,
            sourceFormat: .claudeJSONL,
            isArchived: false
        )
    }
}
