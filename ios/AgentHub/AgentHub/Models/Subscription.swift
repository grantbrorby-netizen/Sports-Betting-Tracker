import Foundation

enum SubscriptionTier: String, Codable, CaseIterable {
    case free
    case starter
    case pro
    case unlimited

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .starter: return "Starter"
        case .pro: return "Pro"
        case .unlimited: return "Unlimited"
        }
    }

    var monthlyPrice: String {
        switch self {
        case .free: return "Free"
        case .starter: return "$9.99/mo"
        case .pro: return "$29.99/mo"
        case .unlimited: return "$99.99/mo"
        }
    }

    var limits: TierLimits {
        switch self {
        case .free:
            return TierLimits(maxAgents: 3, fastPerDay: 10, smartPerDay: 0, deepPerDay: 0, maxPerDay: 0, maxAutomations: 0, visionEnabled: false, historyDays: 3)
        case .starter:
            return TierLimits(maxAgents: 15, fastPerDay: 75, smartPerDay: 0, deepPerDay: 0, maxPerDay: 0, maxAutomations: 0, visionEnabled: false, historyDays: 30)
        case .pro:
            return TierLimits(maxAgents: 50, fastPerDay: 200, smartPerDay: 30, deepPerDay: 5, maxPerDay: 0, maxAutomations: 3, visionEnabled: true, historyDays: 90)
        case .unlimited:
            return TierLimits(maxAgents: -1, fastPerDay: 500, smartPerDay: 100, deepPerDay: 15, maxPerDay: 5, maxAutomations: 10, visionEnabled: true, historyDays: -1)
        }
    }
}

struct TierLimits {
    let maxAgents: Int           // -1 = unlimited
    let fastPerDay: Int
    let smartPerDay: Int
    let deepPerDay: Int
    let maxPerDay: Int
    let maxAutomations: Int
    let visionEnabled: Bool
    let historyDays: Int         // -1 = unlimited

    var isUnlimitedAgents: Bool { maxAgents == -1 }
    var isUnlimitedHistory: Bool { historyDays == -1 }

    func callsRemaining(tier: ModelTier, used: Int) -> Int {
        let limit = limit(for: tier)
        return max(0, limit - used)
    }

    func limit(for tier: ModelTier) -> Int {
        switch tier {
        case .fast: return fastPerDay
        case .smart: return smartPerDay
        case .deep: return deepPerDay
        case .max: return maxPerDay
        }
    }
}

struct UserSubscription: Codable {
    let id: UUID
    let userId: UUID
    let tier: String
    let storekitProductId: String?
    let status: String
    let trialActive: Bool
    let currentPeriodStart: Date?
    let currentPeriodEnd: Date?

    var subscriptionTier: SubscriptionTier {
        SubscriptionTier(rawValue: tier) ?? .free
    }

    var isActive: Bool {
        status == "active"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tier
        case storekitProductId = "storekit_product_id"
        case status
        case trialActive = "trial_active"
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
    }
}
