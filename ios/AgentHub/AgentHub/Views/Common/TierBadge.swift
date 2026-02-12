import SwiftUI

struct TierBadge: View {
    let tier: SubscriptionTier

    var body: some View {
        Text(tier.displayName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.tierColor(for: tier))
            .cornerRadius(6)
    }
}
