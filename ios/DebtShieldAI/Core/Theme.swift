import SwiftUI

/// Semantic colours and spacing.
///
/// Every colour is defined as a light/dark pair rather than a single hex, so
/// the app is legible in both appearances without a second code path. The risk
/// colours were picked to clear WCAG AA (4.5:1) against their own background in
/// each appearance — but they are still never the *only* signal, because
/// `RiskLevel` always ships a label and an SF Symbol alongside.
enum Theme {

    // MARK: - Colour

    static let brand = Color.adaptive(light: 0x1D4ED8, dark: 0x93C5FD)

    static func riskColor(_ level: RiskLevel) -> Color {
        switch level {
        case .low: return .adaptive(light: 0x14602F, dark: 0x6EE7A0)
        case .medium: return .adaptive(light: 0x7A4E00, dark: 0xFCD34D)
        case .high: return .adaptive(light: 0x991B1B, dark: 0xFCA5A5)
        }
    }

    /// Low-saturation fill for badges and chips.
    ///
    /// Deliberately faint. The badge text is a dark tint of the same hue, so a
    /// *lighter* fill raises contrast — an earlier attempt to darken it to 20%
    /// moved the ratio the wrong way and the audit caught it.
    static func riskFill(_ level: RiskLevel) -> Color {
        riskColor(level).opacity(0.12)
    }

    /// Accents for the Compare screen, so each county's bars are consistent
    /// from card to card. Purely decorative — every bar is labelled with its
    /// county name, so nothing is lost without the colour.
    static let comparisonPalette: [Color] = [
        .adaptive(light: 0x1D4ED8, dark: 0x93C5FD),
        .adaptive(light: 0xB45309, dark: 0xFBBF24),
        .adaptive(light: 0x7E22CE, dark: 0xD8B4FE),
        .adaptive(light: 0x0F766E, dark: 0x5EEAD4)
    ]

    static func comparisonColor(at index: Int) -> Color {
        comparisonPalette[index % comparisonPalette.count]
    }

    /// Five-step sequential ramp for the state grid, light and dark variants.
    /// Single hue, increasing intensity — never a rainbow, which carries no
    /// order. The tile always prints its value, so the shade is reinforcement
    /// rather than the only signal.
    static let mapRamp: [Color] = [
        .adaptive(light: 0xE3EDFB, dark: 0x17304F),
        .adaptive(light: 0xC3DAF8, dark: 0x1D4E8F),
        .adaptive(light: 0x8FC0F4, dark: 0x2563EB),
        .adaptive(light: 0x2D6FD4, dark: 0x5B9BF0),
        .adaptive(light: 0x123E82, dark: 0xA9CBFA)
    ]

    /// Text that stays legible on each ramp step.
    static let mapRampForeground: [Color] = [
        .adaptive(light: 0x0B1220, dark: 0xEEF4FF),
        .adaptive(light: 0x0B1220, dark: 0xEEF4FF),
        .adaptive(light: 0x0B1220, dark: 0xFFFFFF),
        .adaptive(light: 0xFFFFFF, dark: 0x0B1220),
        .adaptive(light: 0xFFFFFF, dark: 0x0B1220)
    ]

    /// The gold from the app icon's bars. Used sparingly, as an accent.
    static let accentWarm = Color.adaptive(light: 0xE0A32E, dark: 0xFBD24D)

    /// Brand gradient for headers and the hero. Deep blue, matching the icon.
    static let brandGradient = LinearGradient(
        colors: [
            .adaptive(light: 0x1B3F8F, dark: 0x14294F),
            .adaptive(light: 0x2563EB, dark: 0x1E3A6B)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// A very soft tint behind cards, so surfaces separate without hard lines.
    static let screenGradient = LinearGradient(
        colors: [
            .adaptive(light: 0xF2F5FB, dark: 0x0C1220),
            .adaptive(light: 0xFAFBFD, dark: 0x11131C)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Soft shadow that gives cards a little lift without looking heavy.
    static let cardShadow = Color.black.opacity(0.06)

    /// Tinted well behind an icon, so cards have a focal point.
    static func iconWell(_ tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [tint.opacity(0.22), tint.opacity(0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Readable supporting text.
    ///
    /// SwiftUI's `.secondary` resolves to roughly 4.4:1 on a grouped card, which
    /// fails WCAG AA for body text by a hair — Xcode's accessibility audit
    /// flagged it as "Contrast nearly passed" on essentially every subtitle,
    /// caption, and footnote in the app. These are darker in light mode and
    /// lighter in dark mode, clearing 4.5:1 in both.
    static let secondaryText = Color.adaptive(light: 0x4B5563, dark: 0xC7CDD6)

    /// Card surface that lifts off the grouped background in both appearances.
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let separator = Color(uiColor: .separator)

    // MARK: - Layout

    /// Apple's Human Interface Guidelines put the minimum comfortable target at
    /// 44×44pt. Nothing tappable in this app goes below it.
    static let minimumTapTarget: CGFloat = 44

    enum Spacing {
        static let tight: CGFloat = 8
        static let regular: CGFloat = 12
        static let comfortable: CGFloat = 16
        static let section: CGFloat = 24
    }

    static let cornerRadius: CGFloat = 16
}

extension Color {
    /// Builds a colour that resolves differently in light and dark mode.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
