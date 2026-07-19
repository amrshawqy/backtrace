import SwiftUI

@main
@MainActor
struct BacktraceApp: App {
    @StateObject private var settings: SettingsStore
    @StateObject private var store: SessionStore

    init() {
        let settings = SettingsStore()
        _settings = StateObject(wrappedValue: settings)
        _store = StateObject(wrappedValue: SessionStore(settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(settings)
                .frame(minWidth: 980, minHeight: 620)
                .preferredColorScheme(settings.appearance.preferredColorScheme)
        }
        .defaultSize(width: 1_220, height: 780)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh Sessions") {
                    Task { await store.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Copy Resume Command") {
                    if let session = store.selectedSession {
                        store.copyResumeCommand(for: session)
                    }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(store.selectedSession == nil)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
                .environmentObject(settings)
                .preferredColorScheme(settings.appearance.preferredColorScheme)
        }
    }
}
