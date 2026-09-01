import Foundation
import StoreKit
import Observation

/// A single, one-time **Headroom Pro** unlock — no subscription, because a
/// relocation decision is episodic and taxing someone monthly for it would be
/// exactly the kind of thing this app refuses to do. Pro unlocks a couple of
/// power features (comparing places side by side, an unlimited shortlist); the
/// whole core — your month, the rankings, the metros, the job pay, the move plan —
/// stays free forever, and nothing that touches distress is ever paywalled.
///
/// StoreKit 2. The product lives in App Store Connect (a human step); a bundled
/// `.storekit` config lets it be exercised in the simulator meanwhile. On-device
/// only — the entitlement comes from the App Store transaction, not our server
/// (there is none).
@MainActor
@Observable
final class ProStore {
    /// Must match the non-consumable product ID in App Store Connect.
    static let productID = "com.headroom.pro"

    private(set) var product: Product?
    private(set) var isPro = false
    private(set) var purchasing = false

    init() {
        // Reflect any entitlement already on the device, and keep listening for
        // transactions (a purchase on another device, a restore, a refund). The
        // task lives as long as the app; ProStore is a single app-lifetime object.
        Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await refresh() }
    }

    /// Load the product and the current entitlement.
    func refresh() async {
        if let loaded = try? await Product.products(for: [Self.productID]).first {
            product = loaded
        }
        await updateEntitlement()
    }

    /// The price to show, or a sensible fallback if the product hasn't loaded.
    var displayPrice: String { product?.displayPrice ?? "$6.99" }

    /// Buy Pro. Returns true on a completed, verified purchase.
    @discardableResult
    func purchase() async -> Bool {
        guard let product else { return false }
        purchasing = true
        defer { purchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await updateEntitlement()
                    return isPro
                }
                return false
            case .userCancelled, .pending: return false
            @unknown default: return false
            }
        } catch {
            return false
        }
    }

    /// Restore — the App Store requires a way back to a purchase already made.
    func restore() async {
        try? await AppStore.sync()
        await updateEntitlement()
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
            await updateEntitlement()
        }
    }

    private func updateEntitlement() async {
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let t) = entitlement, t.productID == Self.productID, t.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
    }
}
