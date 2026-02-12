import SwiftUI

struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let isAnnual: Bool
    let isCurrent: Bool
    let onSubscribe: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(tier.displayName)
                    .font(.appTitle)
                    .foregroundStyle(Color.tierColor(for: tier))

                Spacer()

                if isCurrent {
                    Text("Current")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.tierColor(for: tier))
                        .cornerRadius(8)
                }
            }

            // Price
            if tier == .free {
                Text("Free forever")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(isAnnual ? tier.annualPrice : tier.monthlyPrice)
                    .font(.appHeadline)
            }

            Divider()

            // Features
            let limits = tier.limits
            featureRow("Installed Agents", value: limits.isUnlimitedAgents ? "Unlimited" : "\(limits.maxAgents)")
            featureRow("Fast AI/day", value: "\(limits.fastPerDay)")
            if limits.smartPerDay > 0 { featureRow("Smart AI/day", value: "\(limits.smartPerDay)") }
            if limits.deepPerDay > 0 { featureRow("Deep Reasoning/day", value: "\(limits.deepPerDay)") }
            if limits.maxPerDay > 0 { featureRow("Max Reasoning/day", value: "\(limits.maxPerDay)") }
            if limits.maxAutomations > 0 { featureRow("Automations", value: "\(limits.maxAutomations)") }
            if limits.visionEnabled { featureRow("Vision (photo analysis)", value: "Yes") }
            featureRow("History", value: limits.isUnlimitedHistory ? "Unlimited" : "\(limits.historyDays) days")

            // Subscribe button
            if !isCurrent && tier != .free {
                Button(action: onSubscribe) {
                    Text("Subscribe")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrent ? Color.tierColor(for: tier) : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }

    private func featureRow(_ label: String, value: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.tierColor(for: tier))
            Text(label)
                .font(.appCaption)
            Spacer()
            Text(value)
                .font(.appCaption)
                .foregroundStyle(.secondary)
        }
    }
}

// Price helpers
extension SubscriptionTier {
    var annualPrice: String {
        switch self {
        case .free: return "Free"
        case .starter: return "$99.99/yr"
        case .pro: return "$299.99/yr"
        case .unlimited: return "$999.99/yr"
        }
    }
}
