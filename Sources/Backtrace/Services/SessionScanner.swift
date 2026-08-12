import Foundation

protocol SessionScanning: Sendable {
    func scan(
        addedClaudeConfigDirectories: [String],
        hiddenClaudeConfigDirectories: Set<String>
    ) async -> ScanResult
}

struct SessionScanner: SessionScanning, Sendable {
    let home: URL

    init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.home = home
    }

    func scan(
        addedClaudeConfigDirectories: [String] = [],
        hiddenClaudeConfigDirectories: Set<String> = []
    ) async -> ScanResult {
        await Task.detached(priority: .userInitiated) {
            let installations = InstallationDetector(home: home).detectAll()
            let claudeConfigDirectories = ClaudeConfigDirectories.resolve(
                home: home,
                added: addedClaudeConfigDirectories,
                hidden: hiddenClaudeConfigDirectories
            )
            var allSessions: [AssistantSession] = []
            var warnings: [String] = []

            for installation in installations {
                let provider: any SessionProvider
                switch installation.kind {
                case .codex:
                    provider = CodexProvider(home: home)
                case .claude:
                    provider = ClaudeProvider(configDirectories: claudeConfigDirectories)
                case .grok:
                    provider = GrokProvider(home: home)
                case .openCode:
                    provider = OpenCodeProvider(home: home, executableURL: installation.executableURL)
                }

                do {
                    allSessions.append(contentsOf: try provider.sessions())
                } catch {
                    warnings.append("\(installation.kind.displayName): \(error.localizedDescription)")
                }
            }

            var newestByID: [String: AssistantSession] = [:]
            for session in allSessions {
                if let existing = newestByID[session.id], existing.updatedAt >= session.updatedAt {
                    continue
                }
                newestByID[session.id] = session
            }

            return ScanResult(
                installations: installations.sorted { $0.kind.displayName < $1.kind.displayName },
                sessions: newestByID.values.sorted { $0.updatedAt > $1.updatedAt },
                claudeConfigDirectories: claudeConfigDirectories,
                warnings: warnings
            )
        }.value
    }
}
