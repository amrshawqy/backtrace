import Foundation

struct GrokProvider: SessionProvider {
    let assistant = AssistantKind.grok
    let roots: [URL]

    init(home: URL) {
        roots = AssistantKind.grok.defaultHistoryRoots(home: home)
    }

    init(roots: [URL]) {
        self.roots = roots
    }

    func sessions() throws -> [AssistantSession] {
        let candidates = roots.flatMap {
            FileMetadata.files(below: $0, extensions: ["jsonl", "json"])
        }
        var bestByID: [String: AssistantSession] = [:]
        for url in candidates {
            guard let candidate = try? session(at: url) else { continue }
            if let existing = bestByID[candidate.sessionID] {
                let candidateScore = metadataScore(candidate)
                let existingScore = metadataScore(existing)
                if candidateScore > existingScore || candidate.updatedAt > existing.updatedAt {
                    bestByID[candidate.sessionID] = candidate
                }
            } else {
                bestByID[candidate.sessionID] = candidate
            }
        }
        return Array(bestByID.values)
    }

    private func session(at url: URL) throws -> AssistantSession? {
        let objects: [[String: Any]]
        if url.pathExtension == "jsonl" {
            objects = try JSONLReader.sampledObjects(at: url)
        } else {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            if let object = JSONValue.object(from: data) {
                if let messages = object["messages"] as? [[String: Any]] {
                    objects = [object] + messages
                } else {
                    objects = [object]
                }
            } else if let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                objects = array
            } else {
                return nil
            }
        }
        guard !objects.isEmpty else { return nil }

        let nested = objects.flatMap { object -> [[String: Any]] in
            [object, object["payload"] as? [String: Any], object["session"] as? [String: Any]]
                .compactMap { $0 }
        }
        let id = nested.lazy.compactMap {
            JSONValue.string($0, keys: ["sessionId", "session_id", "id"])
        }.first ?? idFromFilename(url)
        guard let id, id.count >= 8 else { return nil }

        let projectPath = nested.lazy.compactMap {
            JSONValue.string($0, keys: ["cwd", "workingDirectory", "workspacePath", "directory"])
        }.first
        let explicitTitle = nested.lazy.compactMap {
            JSONValue.string($0, keys: ["title", "name", "sessionTitle"])
        }.first
        let prompt = SessionText.firstPrompt(in: objects, assistant: .grok)
        guard projectPath != nil || explicitTitle != nil || prompt != nil else { return nil }

        let dates = nested.flatMap { object in
            ["timestamp", "createdAt", "created_at", "updatedAt", "updated_at"]
                .compactMap { FlexibleDateParser.parse(object[$0]) }
        }
        let file = FileMetadata.values(for: url)

        return AssistantSession(
            assistant: .grok,
            sessionID: id,
            title: explicitTitle ?? prompt?.clipped(to: 92) ?? "Untitled Grok session",
            summary: prompt?.clipped(to: 260),
            projectPath: projectPath,
            gitBranch: nested.lazy.compactMap { JSONValue.string($0, keys: ["gitBranch", "branch"]) }.first,
            model: nested.lazy.compactMap { JSONValue.string($0, keys: ["model", "modelId", "model_id"]) }.first,
            createdAt: dates.min(),
            updatedAt: max(file.modified, dates.max() ?? .distantPast),
            messageCount: nil,
            fileSize: file.size,
            sourceURL: url,
            sourceFormat: .grokJSON,
            isArchived: false
        )
    }

    private func idFromFilename(_ url: URL) -> String? {
        let value = url.deletingPathExtension().lastPathComponent
        return value == "metadata" || value == "events" || value == "messages" ? url.deletingLastPathComponent().lastPathComponent : value
    }

    private func metadataScore(_ session: AssistantSession) -> Int {
        [session.projectPath, session.summary, session.model, session.gitBranch]
            .compactMap { $0 }.count
    }
}
