import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: SessionStore
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        List(selection: $store.selection) {
            Section {
                Label {
                    HStack {
                        Text("All Sessions")
                        Spacer()
                        CountBadge(value: store.sessions.count)
                    }
                } icon: {
                    Image(systemName: "tray.full.fill")
                        .foregroundStyle(.secondary)
                }
                .tag(SidebarSelection.all)
            }

            Section("Assistants") {
                if store.installations.isEmpty, store.isScanning {
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small)
                        Text("Detecting assistants")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(store.installations) { installation in
                        HStack(spacing: 10) {
                            AssistantIcon(kind: installation.kind, size: 24)
                            Text(installation.kind.displayName)
                            Spacer()
                            CountBadge(value: store.count(for: installation.kind))
                        }
                        .tag(SidebarSelection.assistant(installation.kind))
                        .help(installation.version ?? installation.executableURL.path)
                    }
                }
            }

            if !settings.trackedFolders.isEmpty {
                Section("Tracked Folders") {
                    ForEach(settings.trackedFolders) { folder in
                        Label {
                            HStack {
                                Text(folder.name).lineLimit(1)
                                Spacer()
                                CountBadge(value: store.count(in: folder))
                            }
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.secondary)
                        }
                        .tag(SidebarSelection.trackedFolder(folder.path))
                        .help(folder.path)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 11) {
                BacktraceMark(size: 34)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Backtrace")
                        .font(.headline)
                    Text("Session manager")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    if store.isScanning {
                        ProgressView()
                            .controlSize(.small)
                        Text("Scanning…")
                    }
                    Spacer()
                    SettingsLink {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.plain)
                    .help("Backtrace Settings")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
            }
            .background(.bar)
        }
        .listStyle(.sidebar)
    }
}

private struct CountBadge: View {
    let value: Int

    var body: some View {
        Text(value.formatted())
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.7), in: Capsule())
    }
}
