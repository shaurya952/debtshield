import SwiftUI

/// The Headroom Pro sheet — a calm, one-time unlock, presented only when someone
/// taps a Pro feature (never as a nag). It's explicit that the whole core is free
/// and that nothing about being short on money is ever paywalled.
struct PaywallView: View {
    let pro: ProStore
    @Environment(\.dismiss) private var dismiss
    @State private var restoring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    header
                    perks
                    freeNote
                    buyButton
                    Button {
                        Task { restoring = true; await pro.restore(); restoring = false
                            if pro.isPro { dismiss() } }
                    } label: {
                        Text(restoring ? "Restoring…" : "Restore a previous purchase")
                            .font(Theme.Typography.subheadline)
                            .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                    }
                    .buttonStyle(.plain).foregroundStyle(Theme.brand)
                    Text("A one-time purchase, not a subscription. You'll be charged once through the App Store; nothing renews.")
                        .font(.caption2).foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center).multilineTextAlignment(.center)
                }
                .padding(Theme.Spacing.comfortable).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }
            .background(Theme.screenBackground)
            .navigationTitle("Headroom Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Not now") { dismiss() } } }
            .onChange(of: pro.isPro) { _, isPro in if isPro { dismiss() } }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            AppIconBadge(systemImage: "sparkles", tint: Theme.brand, size: 52)
            Text("Unlock the power features")
                .font(Theme.Typography.title).fixedSize(horizontal: false, vertical: true)
            Text("A single unlock — no subscription — for the extras that help when you're seriously weighing a move.")
                .font(Theme.Typography.body).foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var perks: some View {
        Card {
            perk("rectangle.split.2x1", "Compare places side by side", "Put two places next to each other — pay, rent and what's left.")
            Divider()
            perk("star.fill", "An unlimited shortlist", "Save as many candidate places as you like, past the free five.")
        }
    }

    private func perk(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            AppIconBadge(systemImage: symbol, tint: Theme.brand, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Typography.body.weight(.semibold))
                Text(detail).font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
    }

    private var freeNote: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.statusColor(.okay))
            Text("The whole core stays free — your month, every ranking, all 116 jobs, your move plan — and anything about being short on money is never behind a paywall.")
                .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.regular)
        .background { RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(Theme.statusColor(.okay).opacity(0.10)) }
    }

    private var buyButton: some View {
        Button {
            Task { if await pro.purchase() { dismiss() } }
        } label: {
            Text(pro.purchasing ? "…" : "Unlock Pro — \(pro.displayPrice)")
                .font(Theme.Typography.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
        }
        .buttonStyle(.borderedProminent)
        .disabled(pro.purchasing || pro.product == nil)
    }
}
