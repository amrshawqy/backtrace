import AppKit
import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var installations: [AssistantInstallation] = []
    @Published private(set) var sessions: [AssistantSession] = []
    @Published private(set) var isScanning = false
    @Published private(set) var lastScan: Date?
    @Published private(set) var warnings: [String] = []
    @Published var selection: SidebarSelection = .all
    @Published var selectedSessionID: String?
    @Published var searchText = ""

    let settings: SettingsStore
    private let scanner: SessionScanner
    private var transcriptCache: [String: TranscriptPreview] = [:]
    private var favoriteIDs: Set<String>
    private let defaults: UserDefaults
    private var cancellables: Set<AnyCancellable> = []

    init(
        settings: SettingsStore,
        scanner: SessionScanner = SessionScanner(),
        defaults: UserDefaults = .standard
    ) {
        self.settings = settings
        self.scanner = scanner
        self.defaults = defaults
        favoriteIDs = Set(defaults.stringArray(forKey: "favoriteSessionIDs") ?? [])
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var visibleSessions: [AssistantSession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).foldedForSearch
        return sessions.filter { session in
            guard matchesSelection(session), matchesTrackedFolders(session) else { return false }
            return query.isEmpty || session.searchableText.contains(query)
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
        guard !isScanning else { return }
        isScanning = true
        let result = await scanner.scan()
        installations = result.installations
        sessions = result.sessions
        warnings = result.warnings
        lastScan = Date()
        isScanning = false

        if let selectedSessionID, sessions.contains(where: { $0.id == selectedSessionID }) {
            return
        }
        selectedSessionID = visibleSessions.first?.id
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

    func isFavorite(_ session: AssistantSession) -> Bool {
        favoriteIDs.contains(session.id)
    }

    func toggleFavorite(_ session: AssistantSession) {
        if favoriteIDs.contains(session.id) {
            favoriteIDs.remove(session.id)
        } else {
            favoriteIDs.insert(session.id)
        }
        defaults.set(Array(favoriteIDs), forKey: "favoriteSessionIDs")
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
        case .trackedFolder(let path):
            session.projectPath == path || session.projectPath?.hasPrefix(path + "/") == true
        }
    }

    private func matchesTrackedFolders(_ session: AssistantSession) -> Bool {
        guard settings.restrictToTrackedFolders, !settings.trackedFolders.isEmpty else { return true }
        guard let projectPath = session.projectPath else { return false }
        return settings.trackedFolders.contains {
            projectPath == $0.path || projectPath.hasPrefix($0.path + "/")
        }
    }
}
