import Foundation

/// Environment variables read from an interactive login shell.
///
/// An app launched from Finder or the Dock inherits none of the shell
/// environment, so `CLAUDE_CONFIG_DIR` and `CODEX_HOME` are invisible unless we
/// ask an interactive login shell for them. Interactive mode also reads
/// `.zshrc`, where many people define these variables. Resolved once per launch
/// because shell startup is relatively expensive and scans repeat every two
/// minutes.
enum LoginShellEnvironment {
    static let values: [String: String] = loadFromShell()

    static func value(for name: String) -> String? {
        if let inherited = ProcessInfo.processInfo.environment[name], !inherited.isEmpty {
            return inherited
        }
        return values[name]
    }

    static func loadFromShell(
        extraEnvironment: [String: String] = [:],
        currentDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [String: String] {
        let names = ["CLAUDE_CONFIG_DIR", "CODEX_HOME"]
        let marker = "BACKTRACE_ENV "
        let command = "for name in \(names.joined(separator: " ")); "
            + #"do print -r -- "\#(marker)$name=${(P)name}"; done"#
        guard let result = ProcessRunner.run(
            executable: URL(fileURLWithPath: "/bin/zsh"),
            arguments: ["-lic", command],
            currentDirectory: currentDirectory,
            extraEnvironment: extraEnvironment
        ), result.status == 0 else { return [:] }

        var found: [String: String] = [:]
        for line in result.text.components(separatedBy: .newlines) {
            guard line.hasPrefix(marker) else { continue }
            let fields = line.dropFirst(marker.count).split(separator: "=", maxSplits: 1).map(String.init)
            guard fields.count == 2, !fields[1].isEmpty else { continue }
            found[fields[0]] = fields[1]
        }
        return found
    }
}

enum ClaudeConfigDirectories {
    /// Every Claude Code configuration directory Backtrace should read, in the
    /// order they are presented: the default location, then the one the shell
    /// points at, then the ones the person added. Nothing else on disk is
    /// looked at; extra profiles are opt-in through Settings.
    static func resolve(
        home: URL,
        added: [String] = [],
        hidden: Set<String> = []
    ) -> [ClaudeConfigDirectory] {
        let defaultURL = defaultURL(home: home)
        var resolved: [ClaudeConfigDirectory] = []
        var seen: Set<String> = []

        func append(_ url: URL, source: ClaudeConfigDirectory.Source) {
            let standardized = URL(
                fileURLWithPath: (url.path as NSString).expandingTildeInPath,
                isDirectory: true
            ).standardizedFileURL
            guard !hidden.contains(standardized.path), seen.insert(standardized.path).inserted else { return }
            resolved.append(
                ClaudeConfigDirectory(
                    url: standardized,
                    source: source,
                    isDefault: standardized.path == defaultURL.path
                )
            )
        }

        append(defaultURL, source: .defaultLocation)
        if let configured = LoginShellEnvironment.value(for: "CLAUDE_CONFIG_DIR"), !configured.isEmpty {
            append(URL(fileURLWithPath: configured, isDirectory: true), source: .environment)
        }
        for path in added {
            append(URL(fileURLWithPath: path, isDirectory: true), source: .added)
        }
        return resolved
    }

    static func defaultURL(home: URL) -> URL {
        home.appendingPathComponent(".claude", isDirectory: true).standardizedFileURL
    }

    /// Checks a hand-typed path before it becomes a config directory. Accepts
    /// `~/.claude-work`, a full path, or a bare name relative to the home
    /// directory, and explains itself when it cannot use what it was given.
    static func validate(
        _ input: String,
        home: URL,
        existing: [ClaudeConfigDirectory]
    ) -> ClaudeConfigDirectoryValidation {
        let path = normalize(input, home: home)
        guard !path.isEmpty else { return .empty }

        var url = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
        // Pointing at the transcripts rather than their parent is the easy
        // mistake here, so read it as the config directory itself.
        if url.lastPathComponent == "projects" {
            url = url.deletingLastPathComponent()
        }
        guard url.path != "/" else {
            return .rejected("Choose a Claude Code config directory, not the whole disk.")
        }

        if let listed = existing.first(where: { $0.url.path == url.path }) {
            return .rejected("Already listed as “\(listed.name)” (\(listed.source.displayName)).")
        }

        var isDirectory: ObjCBool = false
        let manager = FileManager.default
        guard manager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return .rejected("Nothing exists at \(url.path).")
        }
        guard isDirectory.boolValue else {
            return .rejected("That path is a file, not a folder.")
        }
        guard manager.isReadableFile(atPath: url.path) else {
            return .rejected("Backtrace is not allowed to read that folder.")
        }

        let candidate = ClaudeConfigDirectory(url: url, source: .added, isDefault: url == defaultURL(home: home))
        guard candidate.hasProjects else {
            return .accepted(url, note: "No “projects” folder here yet, so this directory has no sessions to show.")
        }
        return .accepted(url, note: nil)
    }

    /// Trims the text, drops quotes picked up from a copied shell command, and
    /// resolves `~` or a bare name against the home directory.
    private static func normalize(_ input: String, home: URL) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        for quote in ["\"", "'"] where text.count > 1 && text.hasPrefix(quote) && text.hasSuffix(quote) {
            text = String(text.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !text.isEmpty else { return "" }

        let expanded = (text as NSString).expandingTildeInPath
        guard !expanded.hasPrefix("/") else { return expanded }
        return home.appendingPathComponent(expanded).path
    }
}
