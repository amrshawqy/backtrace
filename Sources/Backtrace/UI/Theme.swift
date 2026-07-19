import SwiftUI

extension AssistantKind {
    var color: Color {
        switch self {
        case .codex: Color(red: 0.16, green: 0.70, blue: 0.54)
        case .claude: Color(red: 0.83, green: 0.43, blue: 0.25)
        case .grok: Color(red: 0.43, green: 0.52, blue: 0.96)
        case .openCode: Color(red: 0.67, green: 0.49, blue: 0.94)
        }
    }
}

struct AssistantIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    let kind: AssistantKind
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(tileColor)
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(tileBorderColor, lineWidth: 0.75)
            AssistantLogo(kind: kind)
                .frame(width: size * 0.67, height: size * 0.67)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.09), radius: 4, y: 2)
        .accessibilityHidden(true)
    }

    private var tileColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : .white
    }

    private var tileBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.11)
    }
}

private struct AssistantLogo: View {
    @Environment(\.colorScheme) private var colorScheme
    let kind: AssistantKind

    var body: some View {
        Group {
            if let image = officialImage {
                Image(nsImage: image)
                    .renderingMode(usesTemplateRendering ? .template : .original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(templateColor)
            } else {
                Image(systemName: kind.symbolName)
                    .resizable()
                    .scaledToFit()
                    .padding(2)
                    .foregroundStyle(kind.color)
            }
        }
    }

    private var officialImage: NSImage? {
        guard let url = Bundle.main.url(
            forResource: assetName,
            withExtension: "png",
            subdirectory: "AgentIcons"
        ) else { return nil }
        return NSImage(contentsOf: url)
    }

    private var assetName: String {
        guard kind == .openCode else { return kind.iconAssetName }
        return colorScheme == .dark ? "opencode-dark" : "opencode-light"
    }

    private var usesTemplateRendering: Bool {
        kind == .codex || kind == .grok
    }

    private var templateColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

enum SessionDateStyle {
    case relative
    case dateTime
    case time
}

struct SessionDateText: View {
    let date: Date
    var style: SessionDateStyle = .dateTime

    var body: some View {
        Text(displayValue)
            .help(DatePresentation.fullyQualified(date))
    }

    private var displayValue: String {
        switch style {
        case .relative: DatePresentation.relative(date)
        case .dateTime: DatePresentation.dateTime(date)
        case .time: DatePresentation.time(date)
        }
    }
}

struct BacktraceMark: View {
    var size: CGFloat = 36

    var body: some View {
        Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
        .accessibilityLabel("Backtrace")
    }
}

struct ProviderBadge: View {
    let kind: AssistantKind

    var body: some View {
        HStack(spacing: 5) {
            AssistantLogo(kind: kind)
                .frame(width: 12, height: 12)
            Text(kind.displayName)
        }
            .font(.caption.weight(.medium))
            .foregroundStyle(kind.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(kind.color.opacity(0.11), in: Capsule())
    }
}
