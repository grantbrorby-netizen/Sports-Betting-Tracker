import SwiftUI

struct TierGateView: View {
    let requiredTier: SubscriptionTier
    let feature: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundStyle(Color.tierColor(for: requiredTier))

            Text("\(requiredTier.displayName) Feature")
                .font(.appHeadline)

            Text("Upgrade to \(requiredTier.displayName) to unlock \(feature)")
                .font(.appCaption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink("View Plans") {
                SubscriptionView()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 180)
        }
        .padding()
        .cardStyle()
    }
}
