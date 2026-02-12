import Foundation
import StoreKit

@MainActor
class StoreKitManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false

    private var transactionListener: Task<Void, Error>?

    init() {}

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Constants.Products.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Listen for Transactions

    func listenForTransactions() async {
        transactionListener = Task.detached {
            for await result in StoreKit.Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Current Entitlement

    func currentSubscriptionTier() -> SubscriptionTier {
        if purchasedProductIDs.contains(Constants.Products.unlimitedMonthly) ||
           purchasedProductIDs.contains(Constants.Products.unlimitedAnnual) {
            return .unlimited
        }
        if purchasedProductIDs.contains(Constants.Products.proMonthly) ||
           purchasedProductIDs.contains(Constants.Products.proAnnual) {
            return .pro
        }
        if purchasedProductIDs.contains(Constants.Products.starterMonthly) ||
           purchasedProductIDs.contains(Constants.Products.starterAnnual) {
            return .starter
        }
        return .free
    }

    func product(for tier: SubscriptionTier, annual: Bool = false) -> Product? {
        let targetID: String
        switch (tier, annual) {
        case (.starter, false): targetID = Constants.Products.starterMonthly
        case (.starter, true): targetID = Constants.Products.starterAnnual
        case (.pro, false): targetID = Constants.Products.proMonthly
        case (.pro, true): targetID = Constants.Products.proAnnual
        case (.unlimited, false): targetID = Constants.Products.unlimitedMonthly
        case (.unlimited, true): targetID = Constants.Products.unlimitedAnnual
        default: return nil
        }
        return products.first { $0.id == targetID }
    }

    // MARK: - Private

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreKitError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "Purchase verification failed"
    }
}
