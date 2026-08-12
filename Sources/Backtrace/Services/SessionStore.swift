import AppKit
import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var installations: [AssistantInstallation] = []
    @Published private(set) var sessions: [AssistantSession] = []
    @Published private(set) var claudeConfigDirectories: [ClaudeConfigDirectory] = []
    @Published private(set) var isScanning = false
    @Published private(set) var lastScan: Date?
    @Published private(set) var warnings: [String] = []
    @Published var selection: SidebarSelection = .all
    @Published var selectedSessionID: String?
    @Published var searchText = ""
    @Published private(set) var tags: [SessionTag] = []

    let settings: SettingsStore
    private let scanner: any SessionScanning
    private var refreshRequested = false
    private var transcriptCache: [String: TranscriptPreview] = [:]
    private var favoriteIDs: Set<String>
    private var tagIDsBySession: [String: Set<UUID>] = [:]
    private let defaults: UserDefaults
    private var cancellables: Set<AnyCancellable> = []

    private enum Keys {
        static let favoriteSessionIDs = "favoriteSessionIDs"
        static let tagArchive = "sessionTagArchive"
    }

    private struct TagArchive: Codable {
        let tags: [SessionTag]
        let tagIDsBySession: [String: Set<UUID>]
    }

    init(
        settings: SettingsStore,
        scanner: any SessionScanning = SessionScanner(),
        defaults: UserDefaults = .standard
    ) {
        self.settings = settings
        self.scanner = scanner
        self.defaults = defaults
        favoriteIDs = Set(defaults.stringArray(forKey: Keys.favoriteSessionIDs) ?? [])
        if let data = defaults.data(forKey: Keys.tagArchive),
           let archive = try? JSONDecoder().decode(TagArchive.self, from: data) {
            tags = archive.tags
            let validIDs = Set(archive.tags.map(\.id))
            tagIDsBySession = archive.tagIDsBySession.compactMapValues { ids in
                let valid = ids.intersection(validIDs)
                return valid.isEmpty ? nil : valid
            }
        }
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var visibleSessions: [AssistantSession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).foldedForSearch
        return sessions.filter { session in
            guard matchesSelection(session), matchesTrackedFolders(session) else { return false }
            guard !query.isEmpty else { return true }
            let tagSearchText = tags(for: session).map(\.name).joined(separator: " ").foldedForSearch
            return session.searchableText.contains(query) || tagSearchText.contains(query)
        }
        .sorted { lhs, rhs in
            let lhsFavorite = favoriteIDs.contains(lhs.id)
            let rhsFavorite = favoriteIDs.contains(rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    var selectedSession: AssistantSession? {
        guard let selectedSessionID else { return nil }
        return sessions.first { $0.id == selectedSessionID }
    }

    func refresh() async {
        guard !isScanning else {
            refreshRequested = true
            return
        }
        isScanning = true
        repeat {
            refreshRequested = false
            let result = await scanner.scan(
                addedClaudeConfigDirectories: settings.addedClaudeConfigDirectories,
                hiddenClaudeConfigDirectories: settings.hiddenClaudeConfigDirectories
            )
            apply(result)
        } while refreshRequested
        isScanning = false
    }

    private func apply(_ result: ScanResult) {
        installations = result.installations
        sessions = result.sessions
        claudeConfigDirectories = result.claudeConfigDirectories
        warnings = result.warnings
        lastScan = Date()

        if case .claudeConfigDirectory(let path) = selection,
           !claudeConfigDirectories.contains(where: { $0.id == path }) {
            selection = .all
        }

        if selectedSessionID == nil || !sessions.contains(where: { $0.id == selectedSessionID }) {
            selectedSessionID = visibleSessions.first?.id
        }
    }

    func transcript(for session: AssistantSession) async -> TranscriptPreview {
        if let cached = transcriptCache[session.id] {
            return cached
        }

        let loaded = await TranscriptLoader(installations: installations).load(session)
        if !Task.isCancelled {
            transcriptCache[session.id] = loaded
        }
        return loaded
    }

    func count(for kind: AssistantKind) -> Int {
        sessions.lazy.filter { $0.assistant == kind }.count
    }

    func count(in folder: TrackedFolder) -> Int {
        sessions.lazy.filter { session in
            guard let path = session.projectPath else { return false }
            return path == folder.path || path.hasPrefix(folder.path + "/")
        }.count
    }

    func count(in directory: ClaudeConfigDirectory) -> Int {
        sessions.lazy.filter { $0.configDirectory?.id == directory.id }.count
    }

    func count(for tag: SessionTag) -> Int {
        sessions.lazy.filter { self.tagIDsBySession[$0.id]?.contains(tag.id) == true }.count
    }

    func tag(withID id: UUID) -> SessionTag? {
        tags.first { $0.id == id }
    }

    func tags(for session: AssistantSession) -> [SessionTag] {
        guard let assignedIDs = tagIDsBySession[session.id] else { return [] }
        return tags.filter { assignedIDs.contains($0.id) }
    }

    func isTagged(_ session: AssistantSession, with tag: SessionTag) -> Bool {
        tagIDsBySession[session.id]?.contains(tag.id) == true
    }

    var nextTagColor: TagColor {
        let colors = TagColor.allCases
        return colors[tags.count % colors.count]
    }

    @discardableResult
    func createTag(named rawName: String, color: TagColor, assigningTo session: AssistantSession? = nil) -> SessionTag? {
        let name = normalizedTagName(rawName)
        guard !name.isEmpty else { return nil }

        if let existing = tags.first(where: { $0.name.foldedForSearch == name.foldedForSearch }) {
            if let session {
                assign(existing, to: session)
            }
            return existing
        }

        let tag = SessionTag(name: name, color: color)
        tags.append(tag)
        sortTags()
        if let session {
            tagIDsBySession[session.id, default: []].insert(tag.id)
        }
        persistTags()
        return tag
    }

    @discardableResult
    func renameTag(_ tag: SessionTag, to rawName: String) -> Bool {
        let name = normalizedTagName(rawName)
        guard !name.isEmpty else { return false }
        guard !tags.contains(where: {
            $0.id != tag.id && $0.name.foldedForSearch == name.foldedForSearch
        }) else { return false }
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else { return false }

        tags[index] = SessionTag(id: tag.id, name: name, color: tag.color)
        sortTags()
        persistTags()
        return true
    }

    func deleteTag(_ tag: SessionTag) {
        tags.removeAll { $0.id == tag.id }
        tagIDsBySession = tagIDsBySession.compactMapValues { ids in
            let remaining = ids.subtracting([tag.id])
            return remaining.isEmpty ? nil : remaining
        }
        if selection == .tag(tag.id) {
            selection = .all
        }
        persistTags()
    }

    func toggleTag(_ tag: SessionTag, for session: AssistantSession) {
        if isTagged(session, with: tag) {
            tagIDsBySession[session.id]?.remove(tag.id)
            if tagIDsBySession[session.id]?.isEmpty == true {
                tagIDsBySession.removeValue(forKey: session.id)
            }
        } else {
            tagIDsBySession[session.id, default: []].insert(tag.id)
        }
        persistTags()
        objectWillChange.send()
    }

    func assign(_ tag: SessionTag, to session: AssistantSession) {
        guard !isTagged(session, with: tag) else { return }
        tagIDsBySession[session.id, default: []].insert(tag.id)
        persistTags()
        objectWillChange.send()
    }

    func isFavorite(_ session: AssistantSession) -> Bool {
        favoriteIDs.contains(session.id)
    }

    func toggleFavorite(_ session: AssistantSession) {
        if favoriteIDs.contains(session.id) {
            favoriteIDs.remove(session.id)
        } else {
            favoriteIDs.insert(session.id)
        }
        defaults.set(Array(favoriteIDs), forKey: Keys.favoriteSessionIDs)
        objectWillChange.send()
    }

    func copyResumeCommand(for session: AssistantSession) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(session.resumeCommand, forType: .string)
    }

    private func matchesSelection(_ session: AssistantSession) -> Bool {
        switch selection {
        case .all:
            true
        case .assistant(let kind):
            session.assistant == kind
        case .tag(let id):
            tagIDsBySession[session.id]?.contains(id) == true
        case .trackedFolder(let path):
            session.projectPath == path || session.projectPath?.hasPrefix(path + "/") == true
        case .claudeConfigDirectory(let path):
            session.configDirectory?.id == path
        }
    }

    private func matchesTrackedFolders(_ session: AssistantSession) -> Bool {
        guard settings.restrictToTrackedFolders, !settings.trackedFolders.isEmpty else { return true }
        guard let projectPath = session.projectPath else { return false }
        return settings.trackedFolders.contains {
            projectPath == $0.path || projectPath.hasPrefix($0.path + "/")
        }
    }

    private func normalizedTagName(_ name: String) -> String {
        String(name.split(whereSeparator: \.isWhitespace).joined(separator: " ").prefix(32))
    }

    private func sortTags() {
        tags.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func persistTags() {
        let archive = TagArchive(tags: tags, tagIDsBySession: tagIDsBySession)
        if let data = try? JSONEncoder().encode(archive) {
            defaults.set(data, forKey: Keys.tagArchive)
        }
    }
}
