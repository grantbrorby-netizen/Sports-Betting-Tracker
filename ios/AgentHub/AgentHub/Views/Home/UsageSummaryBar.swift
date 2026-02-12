import SwiftUI

struct UsageSummaryBar: View {
    let usage: UsageRecord
    let tier: SubscriptionTier

    private var limits: TierLimits { tier.limits }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Today's Usage")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(tier.displayName)
                    .font(.appCaption)
                    .foregroundStyle(Color.tierColor(for: tier))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.tierColor(for: tier).opacity(0.12))
                    .cornerRadius(6)
            }

            HStack(spacing: 16) {
                usageIndicator(
                    label: "Fast",
                    iconName: ModelTier.fast.iconName,
                    used: usage.fastCalls,
                    limit: limits.fastPerDay,
                    color: .blue
                )

                if limits.smartPerDay > 0 {
                    divider

                    usageIndicator(
                        label: "Smart",
                        iconName: ModelTier.smart.iconName,
                        used: usage.smartCalls,
                        limit: limits.smartPerDay,
                        color: .purple
                    )
                }

                if limits.deepPerDay > 0 {
                    divider

                    usageIndicator(
                        label: "Deep",
                        iconName: ModelTier.deep.iconName,
                        used: usage.deepCalls,
                        limit: limits.deepPerDay,
                        color: .orange
                    )
                }

                if limits.maxPerDay > 0 {
                    divider

                    usageIndicator(
                        label: "Max",
                        iconName: ModelTier.max.iconName,
                        used: usage.maxCalls,
                        limit: limits.maxPerDay,
                        color: .red
                    )
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Usage Indicator

    private func usageIndicator(
        label: String,
        iconName: String,
        used: Int,
        limit: Int,
        color: Color
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 10, weight: .semibold))

                Text(label)
                    .font(.appCaption)
            }
            .foregroundStyle(color)

            Text("\(used)/\(limit)")
                .font(.appSubheadline)
                .foregroundStyle(.primary)
                .monospacedDigit()

            progressBar(used: used, limit: limit, color: color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Progress Bar

    private func progressBar(used: Int, limit: Int, color: Color) -> some View {
        GeometryReader { geometry in
            let progress = limit > 0 ? min(CGFloat(used) / CGFloat(limit), 1.0) : 0
            let isNearLimit = progress >= 0.85
            let barColor = isNearLimit ? Color.statusWarning : color

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.15))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1, height: 40)
    }
}

// MARK: - Preview

#Preview("Pro Tier") {
    UsageSummaryBar(
        usage: UsageRecord(
            userId: UUID(),
            date: "2026-02-12",
            fastCalls: 12,
            smartCalls: 3,
            deepCalls: 1,
            maxCalls: 0,
            totalTokens: 15000,
            byokCalls: 0,
            automationCalls: 0
        ),
        tier: .pro
    )
    .padding()
}

#Preview("Free Tier") {
    UsageSummaryBar(
        usage: UsageRecord(
            userId: UUID(),
            date: "2026-02-12",
            fastCalls: 8,
            smartCalls: 0,
            deepCalls: 0,
            maxCalls: 0,
            totalTokens: 5000,
            byokCalls: 0,
            automationCalls: 0
        ),
        tier: .free
    )
    .padding()
}

#Preview("Unlimited Tier") {
    UsageSummaryBar(
        usage: UsageRecord(
            userId: UUID(),
            date: "2026-02-12",
            fastCalls: 120,
            smartCalls: 45,
            deepCalls: 8,
            maxCalls: 2,
            totalTokens: 85000,
            byokCalls: 5,
            automationCalls: 3
        ),
        tier: .unlimited
    )
    .padding()
}
