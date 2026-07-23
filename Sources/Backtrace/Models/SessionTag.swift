import Foundation

enum TagColor: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case blue
    case indigo
    case purple
    case pink
    case orange
    case green
    case teal

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

struct SessionTag: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let color: TagColor

    init(id: UUID = UUID(), name: String, color: TagColor) {
        self.id = id
        self.name = name
        self.color = color
    }
}
