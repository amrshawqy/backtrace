import SwiftUI

struct TagPill: View {
    let tag: SessionTag
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 4 : 5) {
            Circle()
                .fill(tag.color.color)
                .frame(width: compact ? 5 : 6, height: compact ? 5 : 6)
            Text(tag.name)
                .lineLimit(1)
        }
        .font(compact ? .caption2.weight(.medium) : .caption.weight(.medium))
        .foregroundStyle(tag.color.color)
        .padding(.horizontal, compact ? 7 : 9)
        .padding(.vertical, compact ? 3 : 5)
        .background(tag.color.color.opacity(0.11), in: Capsule())
        .overlay {
            Capsule()
                .stroke(tag.color.color.opacity(0.16), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tag: \(tag.name)")
    }
}

struct SessionTagEditor: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss
    let session: AssistantSession

    @State private var newTagName = ""
    @State private var selectedColor: TagColor = .blue
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            Group {
                if store.tags.isEmpty {
                    ContentUnavailableView {
                        Label("No Tags Yet", systemImage: "tag")
                    } description: {
                        Text("Create the first tag for this session below.")
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 7) {
                            ForEach(store.tags) { tag in
                                tagRow(tag)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            createTagSection
            Divider()

            HStack {
                Text(assignmentSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 430, height: 500)
        .onAppear {
            selectedColor = store.nextTagColor
            if store.tags.isEmpty {
                isNameFocused = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.title2)
                .foregroundStyle(session.assistant.color)
                .frame(width: 34, height: 34)
                .background(session.assistant.color.opacity(0.11), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text("Tags")
                    .font(.headline)
                Text(session.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(16)
    }

    private func tagRow(_ tag: SessionTag) -> some View {
        let isSelected = store.isTagged(session, with: tag)
        return Button {
            store.toggleTag(tag, for: session)
        } label: {
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(tag.color.color.opacity(0.14))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "tag.fill")
                            .font(.caption)
                            .foregroundStyle(tag.color.color)
                    }
                Text(tag.name)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? tag.color.color : Color.secondary.opacity(0.45))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                isSelected ? tag.color.color.opacity(0.075) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(isSelected ? "Remove" : "Add") \(tag.name) tag")
    }

    private var createTagSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Create a new tag")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 9) {
                TextField("Tag name", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
                    .onSubmit(createTag)

                Button("Create & Add", action: createTag)
                    .disabled(normalizedName.isEmpty)
            }

            HStack(spacing: 9) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(TagColor.allCases) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 15, height: 15)
                            .padding(3)
                            .overlay {
                                Circle()
                                    .stroke(color.color, lineWidth: selectedColor == color ? 2 : 0)
                            }
                    }
                    .buttonStyle(.plain)
                    .help(color.displayName)
                    .accessibilityLabel("\(color.displayName) tag color")
                    .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.17))
    }

    private var normalizedName: String {
        newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var assignmentSummary: String {
        let count = store.tags(for: session).count
        return count == 1 ? "1 tag on this session" : "\(count) tags on this session"
    }

    private func createTag() {
        guard store.createTag(named: newTagName, color: selectedColor, assigningTo: session) != nil else {
            return
        }
        newTagName = ""
        selectedColor = store.nextTagColor
        isNameFocused = true
    }
}

struct RenameTagSheet: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss
    let tag: SessionTag

    @State private var name: String
    @State private var validationMessage: String?
    @FocusState private var isFocused: Bool

    init(tag: SessionTag) {
        self.tag = tag
        _name = State(initialValue: tag.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "tag.fill")
                    .foregroundStyle(tag.color.color)
                Text("Rename Tag")
                    .font(.headline)
            }

            TextField("Tag name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit(save)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear { isFocused = true }
    }

    private func save() {
        if store.renameTag(tag, to: name) {
            dismiss()
        } else {
            validationMessage = "Choose a different, unique tag name."
        }
    }
}
