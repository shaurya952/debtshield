import SwiftUI

/// The optional app lock and the "delete my numbers" control, shared by the
/// About screen and the Trust Center. Both surfaces need the exact same
/// controls, so they live here once.
///
/// The delete is deliberately scoped and clearly worded: it removes only the
/// person's own entered figures (via `MoneyPlanStore.clear()`), never the
/// bundled comparison datasets, which are read-only resources in the app bundle.
struct DataSecurityCard: View {
    let store: MoneyPlanStore

    @AppStorage("debtshield.appLockEnabled") private var appLockEnabled = false
    @State private var showDeleteConfirm = false

    var body: some View {
        Card {
            SectionHeader(title: "Your data & security")

            Toggle(isOn: $appLockEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Require Face ID to open")
                        .font(Theme.Typography.body.weight(.semibold))
                    Text("Lock the app with Face ID, Touch ID, or your device passcode.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.brand)
            .frame(minHeight: Theme.minimumTapTarget)
            .accessibilityHint("Requires biometric or passcode unlock each time the app opens")

            Divider()

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: Theme.Spacing.regular) {
                    AppIconBadge(systemImage: "trash.fill", tint: Theme.statusColor(.over), size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete my numbers")
                            .font(Theme.Typography.body.weight(.semibold))
                            .foregroundStyle(Theme.statusColor(.over))
                        Text("Erases the income, essentials, saved months, and area you entered — from this phone. The app and its built-in comparison data stay.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: Theme.minimumTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .confirmationDialog("Delete your numbers?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete my numbers", role: .destructive) { store.clear() }
            Button("Keep them", role: .cancel) {}
        } message: {
            Text("This removes the income, essentials, saved months, and area you entered on this phone. It can't be undone. The app's built-in comparison data (U.S. Census, EIA, BLS) is not affected.")
        }
    }
}

#if DEBUG
#Preview {
    ScrollView { DataSecurityCard(store: .preview(.sampleTight)).padding() }
        .background(Theme.screenBackground)
}
#endif
