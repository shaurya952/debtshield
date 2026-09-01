import SwiftUI

/// The Headroom mark, drawn as a vector so it appears anywhere at any size and
/// adapts to light and dark.
///
/// Matches the app icon: a rounded-square gradient tile with a white upward arrow
/// rising into open space — "headroom", where your money goes further. Deliberately
/// **not** a shield: the old shield read like antivirus / debt-settlement branding,
/// the one association the product is built to avoid.
struct BrandMark: View {
    var size: CGFloat = 40
    /// Renders on a coloured background rather than a neutral one.
    var onColor: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(onColor ? AnyShapeStyle(.white.opacity(0.18)) : AnyShapeStyle(Theme.brandGradient))
            Image(systemName: "arrow.up")
                .font(.system(size: size * 0.54, weight: .bold))
                .foregroundStyle(.white)
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
