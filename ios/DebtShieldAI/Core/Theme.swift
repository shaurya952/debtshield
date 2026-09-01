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

    // MARK: - Personal status colour
    //
    // The green / amber / red for a person's situation. WCAG-AA contrast tuned
    // in each appearance — one set of green/amber/red for the whole app.

    static func statusColor(_ status: MoneyStatus) -> Color {
        switch status {
        case .okay: return .adaptive(light: 0x14602F, dark: 0x6EE7A0)
        case .tight: return .adaptive(light: 0x7A4E00, dark: 0xFCD34D)
        case .over: return .adaptive(light: 0x991B1B, dark: 0xFCA5A5)
        }
    }

    /// Faint fill behind a status pill, matching `riskFill`'s 0.12.
    static func statusFill(_ status: MoneyStatus) -> Color {
        statusColor(status).opacity(0.12)
    }

    /// A soft diagonal wash of the status colour, laid over the hero card so the
    /// month's situation is felt the moment the screen opens — calm, never loud.
    /// It fades to clear, so text contrast over it stays well within AA.
    static func statusWash(_ status: MoneyStatus) -> LinearGradient {
        LinearGradient(
            colors: [statusColor(status).opacity(0.22), statusColor(status).opacity(0.04)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// A little more lift than `cardShadow`, for the one hero card that should
    /// sit above the rest.
    static let heroShadow = Color.black.opacity(0.13)

    /// Colour for one essential segment of the Safe Line bar.
    ///
    /// All four are cool tones (blue / teal / purple / indigo) chosen so none of
    /// them collide with the green/amber/red status meaning — a segment is a
    /// *category*, never a verdict. Every segment is also labelled, so the colour
    /// is reinforcement rather than the only signal.
    static func essentialColor(_ kind: EssentialKind) -> Color {
        switch kind {
        case .housing:        return .adaptive(light: 0x1D4ED8, dark: 0x93C5FD) // blue
        case .homeUpkeep:     return .adaptive(light: 0x92400E, dark: 0xFCD9A8) // amber-brown
        case .food:           return .adaptive(light: 0x0F766E, dark: 0x5EEAD4) // teal
        case .energy:         return .adaptive(light: 0x7E22CE, dark: 0xD8B4FE) // purple
        case .water:          return .adaptive(light: 0x0369A1, dark: 0x7DD3FC) // sky
        case .transportation: return .adaptive(light: 0xC2410C, dark: 0xFDBA74) // orange
        case .personal:       return .adaptive(light: 0xBE185D, dark: 0xF9A8D4) // pink
        case .debt:           return .adaptive(light: 0x4338CA, dark: 0xA5B4FC) // indigo
        }
    }

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
    static let cardShadow = Color.black.opacity(0.09)

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

    // MARK: - Typography

    /// One font scale for the whole app.
    ///
    /// Every token maps to a system Dynamic Type text style, so all of it scales
    /// with the reader's settings and none of it is a fixed point size. Money
    /// figures use the rounded design — friendlier, and it reads as "money" the
    /// way tabular rounded numerals do on a bank card. Everything else is the
    /// standard system face, for one consistent voice.
    enum Typography {
        /// The single big dollar figure on the Safe Line screen.
        static let heroMoney = Font.system(.largeTitle, design: .rounded).weight(.bold)
        /// A money figure inside a card or row.
        static func money(_ style: Font.TextStyle = .body) -> Font {
            .system(style, design: .rounded).weight(.semibold)
        }
        static let title = Font.title2.weight(.bold)
        static let headline = Font.headline
        static let body = Font.body
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
    }
}

/// The app's screen background with a soft, brand-tinted ambient wash at the top —
/// a subtle premium lift used on every main screen so surfaces feel lit, not flat.
/// Colour is never the only signal, so this stays faint and text contrast holds.
struct AppBackdrop: View {
    var body: some View {
        ZStack(alignment: .top) {
            Theme.screenBackground
            LinearGradient(
                colors: [Theme.brand.opacity(0.08), Theme.brand.opacity(0.0)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 460)
            .frame(maxWidth: .infinity)
            .blur(radius: 0.5)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
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
