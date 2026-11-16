import SwiftUI

enum SettingsWidgetBhoomiBrandingColorScheme: String, Codable, CaseIterable {
    case gold = "Gold"
    case saffron = "Saffron"
    case royalBlue = "Royal blue"
    case emerald = "Emerald"
    case crimson = "Crimson"
    case purple = "Purple"
    case dark = "Dark"
    case light = "Light"
    case custom = "Custom"

    func toString() -> String {
        switch self {
        case .gold:
            String(localized: "Gold")
        case .saffron:
            String(localized: "Saffron")
        case .royalBlue:
            String(localized: "Royal blue")
        case .emerald:
            String(localized: "Emerald")
        case .crimson:
            String(localized: "Crimson")
        case .purple:
            String(localized: "Purple")
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
        case .saffron:
            (RgbColor(red: 255, green: 120, blue: 20, opacity: 0.9),
             .white,
             RgbColor(red: 255, green: 200, blue: 60))
        case .royalBlue:
            (RgbColor(red: 20, green: 50, blue: 140, opacity: 0.9),
             .white,
             RgbColor(red: 230, green: 170, blue: 0))
        case .emerald:
            (RgbColor(red: 10, green: 110, blue: 70, opacity: 0.9),
             .white,
             RgbColor(red: 230, green: 200, blue: 90))
        case .crimson:
            (RgbColor(red: 150, green: 15, blue: 30, opacity: 0.9),
             .white,
             RgbColor(red: 240, green: 190, blue: 60))
        case .purple:
            (RgbColor(red: 80, green: 30, blue: 120, opacity: 0.9),
             .white,
             RgbColor(red: 240, green: 190, blue: 60))
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

enum SettingsWidgetBhoomiBrandingStyle: String, Codable, CaseIterable {
    case card = "Card"
    case frame = "Frame"

    func toString() -> String {
        switch self {
        case .card:
            String(localized: "Card")
        case .frame:
            String(localized: "Frame")
        }
    }
}

class SettingsWidgetBhoomiBranding: Codable, ObservableObject {
    private static let defaultScheme = SettingsWidgetBhoomiBrandingColorScheme.gold
    private static let defaultColors = defaultScheme.colors()!
    @Published var style: SettingsWidgetBhoomiBrandingStyle = .card
    var titleStyle = SettingsBhoomiTextStyle(weight: .bold)
    var footerStyle = SettingsBhoomiTextStyle(weight: .semibold)
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
        case style
        case titleStyle
        case footerStyle
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
        try container.encode(.style, style)
        try container.encode(.titleStyle, titleStyle)
        try container.encode(.footerStyle, footerStyle)
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
        let decodedStyle = container.decode(.style, SettingsWidgetBhoomiBrandingStyle.self, .card)
        style = decodedStyle
        let defaultTitleStyle = SettingsBhoomiTextStyle(weight: .bold)
        if decodedStyle == .frame {
            defaultTitleStyle.alignment = .leading
        }
        titleStyle = container.decode(.titleStyle, SettingsBhoomiTextStyle.self, defaultTitleStyle)
        footerStyle = container.decode(.footerStyle, SettingsBhoomiTextStyle.self, .init(weight: .semibold))
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
        new.style = style
        new.titleStyle = titleStyle.clone()
        new.footerStyle = footerStyle.clone()
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
        if style == .frame {
            return CGSize(width: 1920, height: 1080)
        }
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

enum SettingsBhoomiFontWeight: String, Codable, CaseIterable {
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"
    case heavy = "Heavy"
    case black = "Black"

    func toString() -> String {
        switch self {
        case .light:
            String(localized: "Light")
        case .regular:
            String(localized: "Regular")
        case .medium:
            String(localized: "Medium")
        case .semibold:
            String(localized: "Semibold")
        case .bold:
            String(localized: "Bold")
        case .heavy:
            String(localized: "Heavy")
        case .black:
            String(localized: "Black")
        }
    }

    func toUIKit() -> UIFont.Weight {
        switch self {
        case .light:
            .light
        case .regular:
            .regular
        case .medium:
            .medium
        case .semibold:
            .semibold
        case .bold:
            .bold
        case .heavy:
            .heavy
        case .black:
            .black
        }
    }
}

class SettingsBhoomiTextStyle: Codable, ObservableObject {
    @Published var design: SettingsFontDesign = .default
    @Published var weight: SettingsBhoomiFontWeight
    @Published var sizePercent: Double = 100
    @Published var alignment: SettingsHorizontalAlignment = .center

    init(weight: SettingsBhoomiFontWeight) {
        self.weight = weight
    }

    enum CodingKeys: CodingKey {
        case design
        case weight
        case sizePercent
        case alignment
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(.design, design)
        try container.encode(.weight, weight)
        try container.encode(.sizePercent, sizePercent)
        try container.encode(.alignment, alignment)
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        design = container.decode(.design, SettingsFontDesign.self, .default)
        weight = container.decode(.weight, SettingsBhoomiFontWeight.self, .bold)
        sizePercent = container.decode(.sizePercent, Double.self, 100)
        alignment = container.decode(.alignment, SettingsHorizontalAlignment.self, .center)
    }

    func clone() -> SettingsBhoomiTextStyle {
        let new = SettingsBhoomiTextStyle(weight: weight)
        new.design = design
        new.sizePercent = sizePercent
        new.alignment = alignment
        return new
    }

    func font(baseSize: Double) -> UIFont {
        let size = baseSize * sizePercent / 100
        let font = UIFont.systemFont(ofSize: size, weight: weight.toUIKit())
        let design: UIFontDescriptor.SystemDesign = switch self.design {
        case .default:
            .default
        case .serif:
            .serif
        case .rounded:
            .rounded
        case .monospaced:
            .monospaced
        }
        guard let descriptor = font.fontDescriptor.withDesign(design) else {
            return font
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    func textAlignment() -> NSTextAlignment {
        switch alignment {
        case .leading:
            .left
        case .center:
            .center
        case .trailing:
            .right
        }
    }
}
