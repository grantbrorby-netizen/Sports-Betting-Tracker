import SwiftUI

struct TrialBannerView: View {
    let daysRemaining: Int

    @State private var showUpgrade = false

    var body: some View {
        Button {
            Haptics.light()
            showUpgrade = true
        } label: {
            HStack(spacing: 12) {
                iconSection

                textSection

                Spacer()

                upgradeLabel
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(bannerGradient)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showUpgrade) {
            UpgradeDestination()
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 18))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(.white.opacity(0.2))
            .cornerRadius(10)
    }

    // MARK: - Text

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titleText)
                .font(.appSubheadline)
                .foregroundStyle(.white)

            Text("Unlock all features with Pro")
                .font(.appCaption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var titleText: String {
        if daysRemaining == 1 {
            return "1 day left in Pro trial"
        } else {
            return "\(daysRemaining) days left in Pro trial"
        }
    }

    // MARK: - Upgrade CTA

    private var upgradeLabel: some View {
        Text("Upgrade")
            .font(.appCaption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.brandPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.white)
            .cornerRadius(8)
    }

    // MARK: - Gradient

    private var bannerGradient: LinearGradient {
        if daysRemaining <= 2 {
            // Urgent: warm gradient for last 2 days
            return LinearGradient(
                colors: [
                    Color.orange,
                    Color.red.opacity(0.85)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            // Standard brand gradient
            return LinearGradient(
                colors: [
                    .brandGradientStart,
                    .brandGradientEnd
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Upgrade Destination Placeholder

/// Placeholder for the subscription upgrade flow.
/// Replace with actual SubscriptionView once implemented.
private struct UpgradeDestination: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Upgrade to Pro")
                    .font(.appTitle)

                Text("Subscription upgrade flow will appear here.")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("5 days remaining") {
    TrialBannerView(daysRemaining: 5)
        .padding()
}

#Preview("1 day remaining - urgent") {
    TrialBannerView(daysRemaining: 1)
        .padding()
}

#Preview("2 days remaining - urgent") {
    TrialBannerView(daysRemaining: 2)
        .padding()
}
