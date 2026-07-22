import SwiftUI

/// The DebtShield shield, drawn as a vector so it can appear anywhere at any
/// size and adapt to light and dark mode.
///
/// Matches the app icon: a shield split down the middle with three ascending
/// bars across it — the split reads as protection, the bars as the risk drivers
/// the app measures. Using the real mark rather than an SF Symbol means the
/// icon on the home screen and the mark inside the app are the same thing.
struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        func p(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        path.move(to: p(0.5, 0.02))
        path.addCurve(to: p(0.06, 0.20), control1: p(0.37, 0.11), control2: p(0.19, 0.19))
        path.addLine(to: p(0.06, 0.55))
        path.addCurve(to: p(0.5, 0.98), control1: p(0.06, 0.78), control2: p(0.26, 0.91))
        path.addCurve(to: p(0.94, 0.55), control1: p(0.74, 0.91), control2: p(0.94, 0.78))
        path.addLine(to: p(0.94, 0.20))
        path.addCurve(to: p(0.5, 0.02), control1: p(0.81, 0.19), control2: p(0.63, 0.11))
        path.closeSubpath()
        return path
    }
}

/// The full brand mark: shield, split fill, and the three bars.
struct BrandMark: View {
    var size: CGFloat = 40
    /// Renders on a coloured background rather than a neutral one.
    var onColor: Bool = false

    private var shieldFill: Color {
        onColor ? .white : Theme.brand
    }

    private var splitFill: Color {
        onColor ? .white.opacity(0.35) : Theme.brand.opacity(0.45)
    }

    private var barFill: Color {
        onColor ? Color.adaptive(light: 0x1D4ED8, dark: 0x1D4ED8) : Theme.accentWarm
    }

    var body: some View {
        ZStack {
            ShieldShape()
                .fill(shieldFill)

            // Left half, slightly deeper — the "lefthalf.filled" motif.
            ShieldShape()
                .fill(splitFill)
                .mask(alignment: .leading) {
                    Rectangle().frame(width: size * 0.5)
                }

            // Three ascending bars.
            HStack(alignment: .bottom, spacing: size * 0.055) {
                ForEach([0.20, 0.30, 0.42], id: \.self) { height in
                    RoundedRectangle(cornerRadius: size * 0.03, style: .continuous)
                        .fill(barFill)
                        .frame(width: size * 0.10, height: size * height)
                }
            }
            .offset(y: size * 0.06)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The mark plus the wordmark, for headers.
struct BrandLockup: View {
    var size: CGFloat = 34
    var onColor: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.tight) {
            BrandMark(size: size, onColor: onColor)
            VStack(alignment: .leading, spacing: -2) {
                Text("DebtShield")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(onColor ? .white : .primary)
                Text("AI")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(onColor ? .white.opacity(0.85) : Theme.secondaryText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("DebtShield AI")
    }
}

#Preview {
    VStack(spacing: 24) {
        BrandMark(size: 80)
        BrandLockup(size: 40)
        BrandLockup(size: 40, onColor: true)
            .padding()
            .background(Theme.brandGradient)
    }
    .padding()
}
