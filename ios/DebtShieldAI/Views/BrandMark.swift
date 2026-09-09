import SwiftUI

/// The Headroom mark, drawn as a vector so it appears anywhere at any size and
/// adapts to light and dark.
///
/// Matches the app icon: a rounded-square teal tile holding a white roof cap over
/// three ascending bars — home + room to grow, and green reads as money.
/// Deliberately **not** a shield: the old shield read like antivirus / debt-
/// settlement branding, the one association the product is built to avoid.
struct BrandMark: View {
    var size: CGFloat = 40
    /// Renders on a coloured background rather than a neutral one.
    var onColor: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        return shape
            .fill(onColor ? AnyShapeStyle(.white.opacity(0.18)) : AnyShapeStyle(Theme.markGradient))
            .frame(width: size, height: size)
            // Overlay keeps the glyph's 120-pt drawing from inflating the tile's
            // layout; scaleEffect fits it to `size` and clipShape guards any spill.
            .overlay { HomelineMark().scaleEffect(size / 120) }
            .clipShape(shape)
            .accessibilityHidden(true)
    }
}

/// The "Homeline" glyph — a roof cap over three ascending bars — drawn in a fixed
/// 120×120 space so `BrandMark` can scale it to any size. Bars step up in opacity
/// so the rise reads even in one colour; the app icon adds a mint accent bar.
private struct HomelineMark: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 40, y: 52))
                p.addLine(to: CGPoint(x: 62, y: 34))
                p.addLine(to: CGPoint(x: 84, y: 52))
            }
            .stroke(.white, style: StrokeStyle(lineWidth: 6.5, lineCap: .round, lineJoin: .round))

            bar(x: 40, y: 58, height: 28).opacity(0.5)
            bar(x: 55, y: 52, height: 34).opacity(0.75)
            bar(x: 70, y: 46, height: 40)
        }
        .frame(width: 120, height: 120)
    }

    private func bar(x: CGFloat, y: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(.white)
            .frame(width: 10, height: height)
            .position(x: x + 5, y: y + height / 2)
    }
}

/// The mark plus the wordmark, for headers.
struct BrandLockup: View {
    var size: CGFloat = 34
    var onColor: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.tight) {
            BrandMark(size: size, onColor: onColor)
            Text("Headroom")
                .font(.title3.weight(.bold))
                .foregroundStyle(onColor ? .white : .primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Headroom")
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
