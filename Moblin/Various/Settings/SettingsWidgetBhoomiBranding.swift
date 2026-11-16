import SwiftUI

enum SettingsWidgetBhoomiBrandingColorScheme: String, Codable, CaseIterable {
    case gold = "Gold"
    case dark = "Dark"
    case light = "Light"
    case custom = "Custom"

    func toString() -> String {
        switch self {
        case .gold:
            String(localized: "Gold")
        case .dark:
            String(localized: "Dark")
        case .light:
            String(localized: "Light")
        case .custom:
            String(localized: "Custom")
        }
    }

    func colors() -> (background: RgbColor, text: RgbColor, accent: RgbColor)? {
        switch self {
        case .gold:
            (RgbColor(red: 255, green: 250, blue: 225, opacity: 0.9),
             RgbColor(red: 40, green: 30, blue: 0),
             RgbColor(red: 230, green: 170, blue: 0))
        case .dark:
            (RgbColor(red: 20, green: 20, blue: 24, opacity: 0.85),
             .white,
             RgbColor(red: 230, green: 170, blue: 0))
        case .light:
            (RgbColor(red: 255, green: 255, blue: 255, opacity: 0.9),
             .black,
             RgbColor(red: 60, green: 60, blue: 60))
        case .custom:
            nil
        }
    }
}

class SettingsWidgetBhoomiBranding: Codable, ObservableObject {
    private static let defaultScheme = SettingsWidgetBhoomiBrandingColorScheme.gold
    private static let defaultColors = defaultScheme.colors()!
    @Published var showLogo = true
    @Published var header = "Bhoomi Creatives"
    @Published var footer = ""
    @Published var colorScheme = defaultScheme
    var backgroundColor = defaultColors.background
    @Published var backgroundColorColor: Color
    var textColor = defaultColors.text
    @Published var textColorColor: Color
    var accentColor = defaultColors.accent
    @Published var accentColorColor: Color

    init() {
        backgroundColorColor = backgroundColor.color()
        textColorColor = textColor.color()
        accentColorColor = accentColor.color()
    }

    enum CodingKeys: CodingKey {
        case showLogo
        case header
        case footer
        case colorScheme
        case backgroundColor
        case textColor
        case accentColor
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(.showLogo, showLogo)
        try container.encode(.header, header)
        try container.encode(.footer, footer)
        try container.encode(.colorScheme, colorScheme)
        try container.encode(.backgroundColor, backgroundColor)
        try container.encode(.textColor, textColor)
        try container.encode(.accentColor, accentColor)
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showLogo = container.decode(.showLogo, Bool.self, true)
        header = container.decode(.header, String.self, "Bhoomi Creatives")
        footer = container.decode(.footer, String.self, "")
        colorScheme = container.decode(
            .colorScheme,
            SettingsWidgetBhoomiBrandingColorScheme.self,
            Self.defaultScheme
        )
        backgroundColor = container.decode(.backgroundColor, RgbColor.self, Self.defaultColors.background)
        textColor = container.decode(.textColor, RgbColor.self, Self.defaultColors.text)
        accentColor = container.decode(.accentColor, RgbColor.self, Self.defaultColors.accent)
        backgroundColorColor = backgroundColor.color()
        textColorColor = textColor.color()
        accentColorColor = accentColor.color()
    }

    func setColorScheme(_ scheme: SettingsWidgetBhoomiBrandingColorScheme) {
        colorScheme = scheme
        guard let colors = scheme.colors() else {
            return
        }
        backgroundColor = colors.background
        textColor = colors.text
        accentColor = colors.accent
        backgroundColorColor = backgroundColor.color()
        textColorColor = textColor.color()
        accentColorColor = accentColor.color()
    }

    func clone() -> SettingsWidgetBhoomiBranding {
        let new = SettingsWidgetBhoomiBranding()
        new.showLogo = showLogo
        new.header = header
        new.footer = footer
        new.colorScheme = colorScheme
        new.backgroundColor = backgroundColor
        new.textColor = textColor
        new.accentColor = accentColor
        new.backgroundColorColor = backgroundColorColor
        new.textColorColor = textColorColor
        new.accentColorColor = accentColorColor
        return new
    }

    func cardSize() -> CGSize {
        var height = 40.0
        if showLogo {
            height += 400
        }
        if !header.isEmpty {
            height += 90
        }
        if !footer.isEmpty {
            height += 70
        }
        return CGSize(width: 600, height: max(height, 120))
    }
}
