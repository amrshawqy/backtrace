import Foundation

enum JSONValue {
    static func object(from data: Data) -> [String: Any]? {
        (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    static func string(_ object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = object[key] as? String, !value.isEmpty { return value }
        }
        return nil
    }

    static func object(_ object: [String: Any], key: String) -> [String: Any]? {
        object[key] as? [String: Any]
    }

    static func milliseconds(_ object: [String: Any], keys: [String]) -> Date? {
        for key in keys {
            if let value = object[key] as? NSNumber {
                let seconds = value.doubleValue > 10_000_000_000
                    ? value.doubleValue / 1_000
                    : value.doubleValue
                return Date(timeIntervalSince1970: seconds)
            }
        }
        return nil
    }

    static func textContent(_ value: Any?) -> String? {
        if let text = value as? String {
            return text
        }
        guard let items = value as? [[String: Any]] else { return nil }
        let texts = items.compactMap { item -> String? in
            let type = item["type"] as? String
            guard type == nil || type == "text" || type == "input_text" || type == "output_text" else {
                return nil
            }
            return string(item, keys: ["text", "content"])
        }
        guard !texts.isEmpty else { return nil }
        return texts.joined(separator: "\n")
    }
}

enum FlexibleDateParser {
    static func parse(_ value: Any?) -> Date? {
        if let number = value as? NSNumber {
            let raw = number.doubleValue
            return Date(timeIntervalSince1970: raw > 10_000_000_000 ? raw / 1_000 : raw)
        }
        guard let string = value as? String else { return nil }
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string) {
            return date
        }
        return try? Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(string)
    }
}
