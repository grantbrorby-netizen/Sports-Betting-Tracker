import Foundation

actor SubscriptionService {
    static let shared = SubscriptionService()

    func fetchSubscription() async throws -> UserSubscription {
        let url = AppEnvironment.current.supabaseURL.appendingPathComponent("rest/v1/subscriptions")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "limit", value: "1"),
        ]

        let subs: [UserSubscription] = try await APIClient.shared.request(url: components.url!)

        guard let sub = subs.first else {
            // Return free tier default
            return UserSubscription(
                id: UUID(),
                userId: UUID(),
                tier: "free",
                storekitProductId: nil,
                status: "active",
                trialActive: false,
                currentPeriodStart: nil,
                currentPeriodEnd: nil
            )
        }

        return sub
    }

    func fetchTierConfig() async throws -> [SubscriptionTierConfig] {
        let url = AppEnvironment.current.supabaseURL.appendingPathComponent("rest/v1/subscription_tiers")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "price_monthly.asc"),
        ]

        return try await APIClient.shared.request(url: components.url!)
    }
}

struct SubscriptionTierConfig: Codable, Identifiable {
    let id: String
    let name: String
    let priceMonthly: Double
    let priceAnnual: Double
    let maxInstalledAgents: Int
    let fastCallsPerDay: Int
    let smartCallsPerDay: Int
    let deepCallsPerDay: Int
    let maxCallsPerDay: Int
    let maxAutomations: Int
    let visionEnabled: Bool
    let historyRetentionDays: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case priceMonthly = "price_monthly"
        case priceAnnual = "price_annual"
        case maxInstalledAgents = "max_installed_agents"
        case fastCallsPerDay = "fast_calls_per_day"
        case smartCallsPerDay = "smart_calls_per_day"
        case deepCallsPerDay = "deep_calls_per_day"
        case maxCallsPerDay = "max_calls_per_day"
        case maxAutomations = "max_automations"
        case visionEnabled = "vision_enabled"
        case historyRetentionDays = "history_retention_days"
    }
}
