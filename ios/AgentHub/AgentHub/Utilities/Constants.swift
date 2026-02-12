import Foundation

enum Constants {
    // MARK: - StoreKit Product IDs
    enum Products {
        static let starterMonthly = "com.agenthub.starter.monthly"
        static let starterAnnual = "com.agenthub.starter.annual"
        static let proMonthly = "com.agenthub.pro.monthly"
        static let proAnnual = "com.agenthub.pro.annual"
        static let unlimitedMonthly = "com.agenthub.unlimited.monthly"
        static let unlimitedAnnual = "com.agenthub.unlimited.annual"

        static let allProductIDs: Set<String> = [
            starterMonthly, starterAnnual,
            proMonthly, proAnnual,
            unlimitedMonthly, unlimitedAnnual
        ]
    }

    // MARK: - Tier Limits
    enum TierLimits {
        static let freeAgents = 3
        static let starterAgents = 15
        static let proAgents = 50

        static let freeFastCalls = 10
        static let starterFastCalls = 75
        static let proFastCalls = 200
        static let unlimitedFastCalls = 500

        static let proSmartCalls = 30
        static let unlimitedSmartCalls = 100

        static let proDeepCalls = 5
        static let unlimitedDeepCalls = 15

        static let unlimitedMaxCalls = 5

        static let proAutomations = 3
        static let unlimitedAutomations = 10
    }

    // MARK: - Trial
    enum Trial {
        static let durationDays = 7
    }

    // MARK: - API Paths
    enum API {
        static let aiBroker = "ai-broker"
        static let agentRegistry = "agent-registry"
        static let userAPIKeys = "user-api-keys"
        static let automations = "automations"
        static let subscriptionWebhook = "subscription-webhook"
    }

    // MARK: - History Retention (days)
    enum HistoryRetention {
        static let free = 3
        static let starter = 30
        static let pro = 90
        static let unlimited = -1 // unlimited
    }

    // MARK: - Categories
    static let agentCategories = [
        "writing", "finance", "productivity",
        "health", "cooking", "legal"
    ]
}
