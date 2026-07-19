import Foundation

enum DatePresentation {
    static func relative(_ date: Date, relativeTo now: Date = Date()) -> String {
        let interval = date.timeIntervalSince(now)
        let magnitude = abs(interval)

        guard magnitude >= 60 else { return "Now" }

        let unit: (value: Int, singular: String, plural: String)
        switch magnitude {
        case ..<3_600:
            unit = (max(1, Int(magnitude / 60)), "min", "min")
        case ..<86_400:
            unit = (max(1, Int(magnitude / 3_600)), "hr", "hr")
        case ..<604_800:
            unit = (max(1, Int(magnitude / 86_400)), "day", "days")
        case ..<2_592_000:
            unit = (max(1, Int(magnitude / 604_800)), "wk", "wk")
        case ..<31_536_000:
            unit = (max(1, Int(magnitude / 2_592_000)), "mo", "mo")
        default:
            unit = (max(1, Int(magnitude / 31_536_000)), "yr", "yr")
        }

        let label = unit.value == 1 ? unit.singular : unit.plural
        return interval > 0
            ? "in \(unit.value) \(label)"
            : "\(unit.value) \(label) ago"
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func fullyQualified(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .full
        formatter.timeStyle = .short

        let timeZone = TimeZone.autoupdatingCurrent
        let abbreviation = timeZone.abbreviation(for: date) ?? "GMT"
        return "\(formatter.string(from: date)) \(abbreviation) (\(timeZone.identifier))"
    }
}
