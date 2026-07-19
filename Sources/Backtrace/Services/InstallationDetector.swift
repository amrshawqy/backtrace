import Foundation

struct InstallationDetector {
    let home: URL

    func detectAll() -> [AssistantInstallation] {
        let directMatches = Dictionary(uniqueKeysWithValues: AssistantKind.allCases.compactMap { kind in
            directCandidatePaths(for: kind).first(where: isUsableExecutable).map { (kind, $0) }
        })
        let unresolved = AssistantKind.allCases.filter { directMatches[$0] == nil }
        let shellMatches = unresolved.isEmpty ? [:] : resolveAllWithLoginShell()

        return AssistantKind.allCases.compactMap { kind in
            guard let executable = directMatches[kind] ?? shellMatches[kind], isUsableExecutable(executable) else {
                return nil
            }
            return AssistantInstallation(kind: kind, executableURL: executable, version: nil)
        }
    }

    private func directCandidatePaths(for kind: AssistantKind) -> [URL] {
        let name = kind.executableName
        var paths = [
            home.appendingPathComponent(".local/bin/\(name)"),
            home.appendingPathComponent("bin/\(name)"),
            URL(fileURLWithPath: "/opt/homebrew/bin/\(name)"),
            URL(fileURLWithPath: "/usr/local/bin/\(name)"),
            URL(fileURLWithPath: "/usr/bin/\(name)")
        ]

        switch kind {
        case .codex:
            paths.append(URL(fileURLWithPath: "/Applications/Codex.app/Contents/Resources/codex"))
        case .claude:
            paths.append(home.appendingPathComponent(".claude/local/claude"))
        case .grok:
            paths.append(home.appendingPathComponent(".grok/bin/grok"))
        case .openCode:
            paths.append(home.appendingPathComponent(".opencode/bin/opencode"))
        }

        if let path = ProcessInfo.processInfo.environment["PATH"] {
            paths.append(contentsOf: path.split(separator: ":").map {
                URL(fileURLWithPath: String($0), isDirectory: true).appendingPathComponent(name)
            })
        }

        var seen: Set<String> = []
        return paths.filter { seen.insert($0.standardizedFileURL.path).inserted }
    }

    private func resolveAllWithLoginShell() -> [AssistantKind: URL] {
        let command = #"for name in codex claude grok opencode; do found=$(whence -p "$name" 2>/dev/null); [[ -n "$found" ]] && print -r -- "$name=$found"; done"#
        guard let result = ProcessRunner.run(
            executable: URL(fileURLWithPath: "/bin/zsh"),
            arguments: ["-lc", command],
            currentDirectory: home
        ), result.status == 0 else { return [:] }

        var matches: [AssistantKind: URL] = [:]
        for line in result.text.components(separatedBy: .newlines) {
            let fields = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard fields.count == 2,
                  let kind = AssistantKind.allCases.first(where: { $0.executableName == fields[0] }),
                  fields[1].hasPrefix("/") else { continue }
            let url = URL(fileURLWithPath: fields[1])
            if !isCMuxShim(url) { matches[kind] = url }
        }
        return matches
    }

    private func isUsableExecutable(_ url: URL) -> Bool {
        !isCMuxShim(url) && FileManager.default.isExecutableFile(atPath: url.path)
    }

    private func isCMuxShim(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        return path.contains("cmux-cli-shims") || path.contains("cmux.app/contents/resources/bin")
    }

}
