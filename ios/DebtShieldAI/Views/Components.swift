import SwiftUI

// MARK: - Risk badge

/// Risk shown three ways at once: shape, colour, and words.
///
/// Removing any one of the three still leaves the meaning intact, which is the
/// whole point — greyscale, colour-blindness, and VoiceOver each lose a
/// different channel.
struct RiskBadge: View {
    let level: RiskLevel
    var compact: Bool = false

    var body: some View {
        Label {
            Text(compact ? level.label : "\(level.label) risk")
                .font(.subheadline.weight(.semibold))
        } icon: {
            Image(systemName: level.symbolName)
                .imageScale(.small)
        }
        .foregroundStyle(Theme.riskColor(level))
        .padding(.horizontal, Theme.Spacing.regular)
        .padding(.vertical, Theme.Spacing.tight)
        .background(Theme.riskFill(level), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(level.label) risk")
        .accessibilityHint(level.plainEnglish)
    }
}

/// Shown in place of a `RiskBadge` for counties the Census does not publish
/// enough data to score. Deliberately neutral — an unscored county is not a
/// safe county, and must not read as one.
struct UnscoredBadge: View {
    var body: some View {
        Label {
            Text("No score")
                .font(.subheadline.weight(.semibold))
        } icon: {
            Image(systemName: "questionmark.circle.fill")
                .imageScale(.small)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, Theme.Spacing.regular)
        .padding(.vertical, Theme.Spacing.tight)
        .background(Color(uiColor: .secondarySystemFill), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("No score")
        .accessibilityHint("The Census does not publish enough data to score this county")
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
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(Theme.iconWell(tint), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .accessibilityHidden(true)

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
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.brand)
                .frame(width: 30, height: 30)
                .background(Theme.iconWell(Theme.brand), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)

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
        .background(Theme.screenBackground)
    }
}
