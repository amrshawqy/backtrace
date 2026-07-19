import AppKit
import Combine
import Foundation
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var trackedFolders: [TrackedFolder] = []
    @Published var restrictToTrackedFolders: Bool {
        didSet { defaults.set(restrictToTrackedFolders, forKey: Keys.restrictToTrackedFolders) }
    }
    @Published var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let trackedFolders = "trackedFolders"
        static let restrictToTrackedFolders = "restrictToTrackedFolders"
        static let appearance = "appearance"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restrictToTrackedFolders = defaults.bool(forKey: Keys.restrictToTrackedFolders)
        appearance = defaults.string(forKey: Keys.appearance).flatMap(AppAppearance.init(rawValue:)) ?? .system
        if let data = defaults.data(forKey: Keys.trackedFolders),
           let values = try? JSONDecoder().decode([TrackedFolder].self, from: data) {
            trackedFolders = values
        }
    }

    func chooseAndAddFolder() {
        let panel = NSOpenPanel()
        panel.title = "Add a project folder"
        panel.prompt = "Track Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            addFolder(url)
        }
    }

    func addFolder(_ url: URL) {
        let path = url.standardizedFileURL.path
        guard !trackedFolders.contains(where: { $0.path == path }) else { return }
        trackedFolders.append(TrackedFolder(path: path))
        trackedFolders.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        persist()
    }

    func removeFolder(_ folder: TrackedFolder) {
        trackedFolders.removeAll { $0.id == folder.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(trackedFolders) {
            defaults.set(data, forKey: Keys.trackedFolders)
        }
    }
}
