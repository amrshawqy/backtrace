import AppKit
import SwiftUI

struct SessionListView: View {
    @EnvironmentObject private var store: SessionStore

    private var title: String {
        switch store.selection {
        case .all: "Sessions"
        case .assistant(let kind): kind.displayName
        case .trackedFolder(let path): URL(fileURLWithPath: path).lastPathComponent
        }
    }

    var body: some View {
        Group {
            if store.visibleSessions.isEmpty {
                ContentUnavailableView {
                    Label(
                        store.searchText.isEmpty ? "No Sessions" : "No Results",
                        systemImage: store.searchText.isEmpty ? "bubble.left.and.exclamationmark.bubble.right" : "magnifyingglass"
                    )
                } description: {
                    Text(emptyMessage)
                } actions: {
                    if !store.searchText.isEmpty {
                        Button("Clear Search") { store.searchText = "" }
                    } else {
                        Button("Refresh") { Task { await store.refresh() } }
                    }
                }
            } else {
                List(selection: $store.selectedSessionID) {
                    ForEach(store.visibleSessions) { session in
                        SessionRow(session: session)
                            .tag(session.id)
                            .contextMenu {
                                Button("Copy Resume Command") {
                                    store.copyResumeCommand(for: session)
                                }
                                Button(store.isFavorite(session) ? "Unpin Session" : "Pin Session") {
                                    store.toggleFavorite(session)
                                }
                                Divider()
                                Button("Reveal Transcript in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([session.sourceURL])
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(title)
        .searchable(text: $store.searchText, placement: .toolbar, prompt: "Title, folder, branch, or ID")
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await store.refresh() }
                } label: {
                    if store.isScanning {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(store.isScanning)
                .help("Refresh Sessions (⌘R)")
            }
        }
    }

    private var emptyMessage: String {
        if !store.searchText.isEmpty {
            return "Try a session title, project folder, branch, model, or session ID."
        }
        if store.installations.isEmpty {
            return "No supported CLI assistant was detected in your shell or common install locations."
        }
        return "No saved sessions were found for this selection."
    }
}

private struct SessionRow: View {
    @EnvironmentObject private var store: SessionStore
    let session: AssistantSession

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            AssistantIcon(kind: session.assistant, size: 31)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(session.title)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                    if store.isFavorite(session) {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(session.assistant.color)
                    }
                    Spacer(minLength: 4)
                    SessionDateText(date: session.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Label(session.projectName, systemImage: "folder")
                    if let branch = session.gitBranch, !branch.isEmpty {
                        Text("·")
                        Label(branch, systemImage: "arrow.triangle.branch")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if let summary = session.summary, summary != session.title {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
