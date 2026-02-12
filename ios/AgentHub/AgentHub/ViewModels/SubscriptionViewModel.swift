import Foundation
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var currentTier: SubscriptionTier = .free
    @Published var subscription: UserSubscription?
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storeKit = StoreKitManager()

    var isTrialActive: Bool {
        subscription?.trialActive ?? false
    }

    func loadProducts() async {
        await storeKit.loadProducts()
        products = storeKit.products
        await refreshSubscription()
    }

    func listenForTransactions() async {
        await storeKit.listenForTransactions()
    }

    func purchase(tier: SubscriptionTier, annual: Bool = false) async {
        guard let product = storeKit.product(for: tier, annual: annual) else {
            errorMessage = "Product not available"
            return
        }

        isLoading = true
        do {
            let transaction = try await storeKit.purchase(product)
            if transaction != nil {
                currentTier = tier
                Haptics.success()
            }
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
        isLoading = false
    }

    func restorePurchases() async {
        await storeKit.restorePurchases()
        currentTier = storeKit.currentSubscriptionTier()
    }

    private func refreshSubscription() async {
        do {
            subscription = try await SubscriptionService.shared.fetchSubscription()
            currentTier = subscription?.subscriptionTier ?? storeKit.currentSubscriptionTier()
        } catch {
            currentTier = storeKit.currentSubscriptionTier()
        }
    }
}
