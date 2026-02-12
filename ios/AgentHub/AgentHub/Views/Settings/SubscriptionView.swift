import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var subscriptionVM: SubscriptionViewModel
    @State private var isAnnual = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Toggle Monthly/Annual
                Picker("Billing", selection: $isAnnual) {
                    Text("Monthly").tag(false)
                    Text("Annual (save 17%)").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tier Cards
                ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                    SubscriptionTierCard(
                        tier: tier,
                        isAnnual: isAnnual,
                        isCurrent: subscriptionVM.currentTier == tier,
                        onSubscribe: {
                            Task { await subscriptionVM.purchase(tier: tier, annual: isAnnual) }
                        }
                    )
                }

                // BYOK note
                Text("Bring Your Own Key (BYOK) is available on all tiers with unlimited calls.")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Restore
                Button("Restore Purchases") {
                    Task { await subscriptionVM.restorePurchases() }
                }
                .font(.appSubheadline)
                .foregroundStyle(Color.brandPrimary)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}
