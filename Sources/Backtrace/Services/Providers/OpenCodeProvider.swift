import Foundation

struct OpenCodeProvider: SessionProvider {
    let assistant = AssistantKind.openCode
    let root: URL
    let executableURL: URL?
    let home: URL

    init(home: URL, executableURL: URL?) {
        self.home = home
        root = AssistantKind.openCode.defaultHistoryRoots(home: home)[0]
        self.executableURL = executableURL
    }

    init(root: URL, executableURL: URL? = nil, home: URL) {
        self.root = root
        self.executableURL = executableURL
        self.home = home
    }

    func sessions() throws -> [AssistantSession] {
        var byID: [String: AssistantSession] = [:]
        let legacyRoot = root.appendingPathComponent("storage/session", isDirectory: true)
        for url in FileMetadata.files(below: legacyRoot, extensions: ["json"]) {
            if let session = try? legacySession(at: url) {
                byID[session.sessionID] = session
            }
        }

        if byID.isEmpty, let executableURL {
            for session in cliSessions(executableURL: executableURL) {
                byID[session.sessionID] = session
            }
        }
        return Array(byID.values)
    }

    private func legacySession(at url: URL) throws -> AssistantSession? {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        guard let object = JSONValue.object(from: data),
              let id = object["id"] as? String,
              id != "global" else { return nil }
        let time = object["time"] as? [String: Any]
        let created = FlexibleDateParser.parse(time?["created"])
        let updated = FlexibleDateParser.parse(time?["updated"])
        let file = FileMetadata.values(for: url)
        return AssistantSession(
            assistant: .openCode,
            sessionID: id,
            title: JSONValue.string(object, keys: ["title"]) ?? "Untitled OpenCode session",
            summary: summaryText(object["summary"]),
            projectPath: JSONValue.string(object, keys: ["directory"]),
            gitBranch: nil,
            model: nil,
            createdAt: created,
            updatedAt: max(file.modified, updated ?? .distantPast),
            messageCount: nil,
            fileSize: file.size,
            sourceURL: url,
            sourceFormat: .openCodeLegacy,
            isArchived: false
        )
    }

    private func cliSessions(executableURL: URL) -> [AssistantSession] {
        guard let result = ProcessRunner.run(
            executable: executableURL,
            arguments: ["session", "list", "--format", "json"],
            currentDirectory: home,
            extraEnvironment: ["OPENCODE_DISABLE_AUTOUPDATE": "true"]
        ), result.status == 0,
        let values = parseJSONArray(from: result.output) else { return [] }

        return values.compactMap { object in
            guard let id = object["id"] as? String else { return nil }
            let time = object["time"] as? [String: Any]
            return AssistantSession(
                assistant: .openCode,
                sessionID: id,
                title: JSONValue.string(object, keys: ["title"]) ?? "Untitled OpenCode session",
                summary: summaryText(object["summary"]),
                projectPath: JSONValue.string(object, keys: ["directory"]),
                gitBranch: JSONValue.string(object, keys: ["branch"]),
                model: JSONValue.string(object, keys: ["model", "modelID"]),
                createdAt: FlexibleDateParser.parse(time?["created"] ?? object["createdAt"]),
                updatedAt: FlexibleDateParser.parse(time?["updated"] ?? object["updatedAt"]) ?? .distantPast,
                messageCount: object["messageCount"] as? Int,
                fileSize: 0,
                sourceURL: root,
                sourceFormat: .openCodeCLI,
                isArchived: false
            )
        }
    }

    private func summaryText(_ value: Any?) -> String? {
        if let value = value as? String { return value.clipped(to: 260) }
        guard let object = value as? [String: Any] else { return nil }
        return JSONValue.string(object, keys: ["text", "title", "description"])?.clipped(to: 260)
    }

    private func parseJSONArray(from data: Data) -> [[String: Any]]? {
        if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return array
        }
        guard let start = data.firstIndex(of: 0x5B), let end = data.lastIndex(of: 0x5D), start <= end else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: Data(data[start...end])) as? [[String: Any]]
    }
}
