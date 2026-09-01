import SwiftUI

// MARK: - Press feedback

/// A button style that gives a card a subtle, springy press — the small tactile
/// cue that makes an app feel alive and premium. Respects Reduce Motion.
struct PressableCardStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.975 : 1))
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - App-icon badge

/// A small rounded-square icon in the style of an iOS home-screen app icon: a
/// tinted gradient fill with a white glyph and a soft drop shadow. It's the one
/// icon treatment used across every screen — the home tiles, the action rows,
/// the stat cards, the navigation rows — so the whole app reads as one polished
/// set rather than a mix of flat wells and gradients.
struct AppIconBadge: View {
    let systemImage: String
    var tint: Color = Theme.brand
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [tint, tint.opacity(0.78)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            )
            .shadow(color: tint.opacity(0.32), radius: 5, x: 0, y: 3)
            .accessibilityHidden(true)
    }
}

// MARK: - Action row

/// A tappable card row: a tinted icon, a title and subtitle, and a chevron.
/// The single source of truth for the "leads somewhere" cards on the home and
/// compare screens, so they stay pixel-identical. Wrap it in a `Button` or
/// `NavigationLink`; the button trait and hint come from the caller.
struct ActionRowLabel: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            AppIconBadge(systemImage: systemImage, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(Theme.Spacing.comfortable)
        .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

// MARK: - Plain-language explainer

/// A quiet, consistent "what does this mean?" expander.
///
/// The app's more capable cards — the verdict, the odds — carry a little more
/// under the hood than a first-time reader can guess at. Rather than crowd the
/// card with explanation, this tucks a plain-English answer one tap away, in a
/// voice that's calm and jargon-free. Collapsed by default; the prompt is a soft
/// brand-tinted line, not a heavy control.
struct ExplainerDisclosure<Content: View>: View {
    /// The tappable prompt, e.g. "How this works" or "Why?".
    let label: String
    var systemImage: String = "questionmark.circle"
    @ViewBuilder var content: Content

    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            content
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.tight)
        } label: {
            Label(label, systemImage: systemImage)
                .font(Theme.Typography.subheadline.weight(.semibold))
                .foregroundStyle(Theme.brand)
        }
        .tint(Theme.brand)
        .accessibilityHint(expanded ? "Collapses the explanation" : "Explains this in plain words")
    }
}

// MARK: - Status chip

/// A small, glanceable pill of the month's status — the instant read that lets
/// the eye land on "Tight" before reading a word of the card. Colour plus an SF
/// Symbol plus a label, so the meaning never rides on colour alone.
struct StatusChip: View {
    let status: MoneyStatus

    private var label: String {
        switch status {
        case .okay: return "On track"
        case .tight: return "Tight"
        case .over: return "Over budget"
        }
    }

    private var symbol: String {
        switch status {
        case .okay: return "checkmark.circle.fill"
        case .tight: return "equal.circle.fill"
        case .over: return "exclamationmark.circle.fill"
        }
    }

    var body: some View {
        Label(label, systemImage: symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.statusColor(status))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.statusFill(status), in: Capsule())
            .accessibilityLabel("Status: \(label)")
    }
}

// MARK: - Feature tile

/// A compact, glanceable tile for the home dashboard grid: a tinted icon, a
/// short title, and one supporting line. Two of these sit side by side, so the
/// home screen reads as a small set of clear doors rather than a long scroll.
/// Wrap it in a `NavigationLink`; it carries its own press feedback and a
/// combined VoiceOver label.
struct FeatureTile: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var tint: Color = Theme.brand
    /// A short status word shown as a pill (e.g. an odds read). Optional.
    var badge: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(colors: [tint, tint.opacity(0.78)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                    .shadow(color: tint.opacity(0.35), radius: 6, x: 0, y: 3)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                if let badge {
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(tint, in: Capsule())
                        .accessibilityHidden(true)
                }
            }

            Spacer(minLength: Theme.Spacing.tight)

            Text(title)
                .font(Theme.Typography.body.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .padding(Theme.Spacing.comfortable)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .fill(tint.opacity(0.06))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .strokeBorder(tint.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 5)
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(badge.map { "\($0). \(subtitle)" } ?? subtitle)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Cards

/// Standard rounded surface. Everything on a screen sits in one of these so
/// spacing stays consistent as Dynamic Type grows.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.comfortable)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 4)
        }
    }
}

/// A single headline number with a label and optional supporting line.
struct StatCard: View {
    let label: String
    let value: String
    var detail: String?
    var systemImage: String
    var tint: Color = Theme.brand

    /// The icon column costs width the label needs once text grows.
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Card {
            layout {
                AppIconBadge(systemImage: systemImage, tint: tint, size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    Text(value)
                        .font(.title2.weight(.bold))
                        .contentTransition(.numericText())
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail {
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        // Collapse into one utterance so VoiceOver reads "Counties, 3,142"
        // rather than three disconnected fragments.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(detail.map { "\(value). \($0)" } ?? value)
    }

    /// Side by side normally, stacked once text is large.
    private var layout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.tight))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.tight))
    }
}

// MARK: - Navigation row

/// A tappable row inside a card, used for drilling into a county's detail
/// screens. Presents as one VoiceOver button with a full sentence.
struct DetailNavigationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout: AnyLayout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.tight))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.tight))
        return layout {
            AppIconBadge(systemImage: systemImage, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Theme.Spacing.tight)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
        }
        .frame(minHeight: Theme.minimumTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Loading

/// Shimmering placeholder block. Respects Reduce Motion by holding still
/// instead of animating.
struct SkeletonBlock: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(uiColor: .tertiarySystemFill))
            .frame(height: height)
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, Color(uiColor: .systemBackground).opacity(0.55), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

/// Full-screen loading state for the dashboard.
struct DashboardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.section) {
            SkeletonBlock(height: 28, cornerRadius: 8)
                .frame(maxWidth: 220)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.regular) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonBlock(height: 88, cornerRadius: Theme.cornerRadius)
                }
            }
            SkeletonBlock(height: 220, cornerRadius: Theme.cornerRadius)
            SkeletonBlock(height: 180, cornerRadius: Theme.cornerRadius)
        }
        .padding(Theme.Spacing.comfortable)
        // One announcement instead of a dozen shimmering rectangles.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading county data")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Error

/// Friendly failure screen. The plain-language message leads; the technical
/// detail is tucked behind a disclosure for whoever needs it.
struct ErrorStateView: View {
    let error: DataError
    var retry: () async -> Void

    @State private var showsDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.comfortable) {
                Image(systemName: "exclamationmark.icloud")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)

                Text(error.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(error.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)

                Button {
                    Task { await retry() }
                } label: {
                    Text("Try again")
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Reloads the built-in county dataset")

                if let detail = error.technicalDetail {
                    DisclosureGroup("Technical details", isExpanded: $showsDetail) {
                        Text(detail)
                            .font(.footnote.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(.top, Theme.Spacing.tight)
                    }
                    .font(.subheadline)
                    .padding(Theme.Spacing.comfortable)
                    .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                }
            }
            .padding(Theme.Spacing.section)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background { AppBackdrop() }
    }
}
