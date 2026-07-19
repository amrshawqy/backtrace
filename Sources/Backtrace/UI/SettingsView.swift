import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: SessionStore
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        TabView {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Label(appearance.displayName, systemImage: appearance.symbolName)
                                .tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("Detected assistants") {
                    if store.installations.isEmpty {
                        Text("No supported assistants detected")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.installations) { installation in
                            HStack(spacing: 10) {
                                AssistantIcon(kind: installation.kind, size: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(installation.kind.displayName)
                                    Text(installation.version ?? installation.executableURL.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section {
                    Label("Session files are read-only", systemImage: "lock.shield.fill")
                    Text("Backtrace reads local transcript metadata and previews. It never uploads conversations, modifies a session, or launches an assistant.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("General", systemImage: "gearshape") }

            Form {
                Section {
                    if settings.trackedFolders.isEmpty {
                        Text("Add project folders to organize or limit the session list. The assistants’ global history stores are still discovered automatically.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(settings.trackedFolders) { folder in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading) {
                                    Text(folder.name)
                                    Text(folder.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button {
                                    settings.removeFolder(folder)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        settings.chooseAndAddFolder()
                    } label: {
                        Label("Add Folder…", systemImage: "plus")
                    }
                } header: {
                    Text("Tracked project folders")
                }

                if !settings.trackedFolders.isEmpty {
                    Section {
                        Toggle("Show only sessions in tracked folders", isOn: $settings.restrictToTrackedFolders)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Folders", systemImage: "folder") }
        }
        .frame(width: 590, height: 450)
    }
}
