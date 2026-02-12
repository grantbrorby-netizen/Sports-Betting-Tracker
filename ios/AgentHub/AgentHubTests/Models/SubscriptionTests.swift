import XCTest
@testable import AgentHub

final class SubscriptionTests: XCTestCase {

    // MARK: - SubscriptionTier Display

    func testTierDisplayNames() {
        XCTAssertEqual(SubscriptionTier.free.displayName, "Free")
        XCTAssertEqual(SubscriptionTier.starter.displayName, "Starter")
        XCTAssertEqual(SubscriptionTier.pro.displayName, "Pro")
        XCTAssertEqual(SubscriptionTier.unlimited.displayName, "Unlimited")
    }

    func testTierMonthlyPrices() {
        XCTAssertEqual(SubscriptionTier.free.monthlyPrice, "Free")
        XCTAssertEqual(SubscriptionTier.starter.monthlyPrice, "$9.99/mo")
        XCTAssertEqual(SubscriptionTier.pro.monthlyPrice, "$29.99/mo")
        XCTAssertEqual(SubscriptionTier.unlimited.monthlyPrice, "$99.99/mo")
    }

    // MARK: - TierLimits

    func testFreeTierLimits() {
        let limits = SubscriptionTier.free.limits
        XCTAssertEqual(limits.maxAgents, 3)
        XCTAssertEqual(limits.fastPerDay, 10)
        XCTAssertEqual(limits.smartPerDay, 0)
        XCTAssertEqual(limits.deepPerDay, 0)
        XCTAssertEqual(limits.maxPerDay, 0)
        XCTAssertEqual(limits.maxAutomations, 0)
        XCTAssertFalse(limits.visionEnabled)
        XCTAssertEqual(limits.historyDays, 3)
        XCTAssertFalse(limits.isUnlimitedAgents)
        XCTAssertFalse(limits.isUnlimitedHistory)
    }

    func testProTierLimits() {
        let limits = SubscriptionTier.pro.limits
        XCTAssertEqual(limits.maxAgents, 50)
        XCTAssertEqual(limits.fastPerDay, 200)
        XCTAssertEqual(limits.smartPerDay, 30)
        XCTAssertEqual(limits.deepPerDay, 5)
        XCTAssertEqual(limits.maxPerDay, 0)
        XCTAssertEqual(limits.maxAutomations, 3)
        XCTAssertTrue(limits.visionEnabled)
        XCTAssertEqual(limits.historyDays, 90)
    }

    func testUnlimitedTierLimits() {
        let limits = SubscriptionTier.unlimited.limits
        XCTAssertEqual(limits.maxAgents, -1)
        XCTAssertTrue(limits.isUnlimitedAgents)
        XCTAssertEqual(limits.fastPerDay, 500)
        XCTAssertEqual(limits.smartPerDay, 100)
        XCTAssertEqual(limits.deepPerDay, 15)
        XCTAssertEqual(limits.maxPerDay, 5)
        XCTAssertEqual(limits.maxAutomations, 10)
        XCTAssertTrue(limits.visionEnabled)
        XCTAssertEqual(limits.historyDays, -1)
        XCTAssertTrue(limits.isUnlimitedHistory)
    }

    // MARK: - TierLimits Computation

    func testCallsRemainingCalculation() {
        let limits = SubscriptionTier.pro.limits

        XCTAssertEqual(limits.callsRemaining(tier: .fast, used: 0), 200)
        XCTAssertEqual(limits.callsRemaining(tier: .fast, used: 150), 50)
        XCTAssertEqual(limits.callsRemaining(tier: .fast, used: 200), 0)
        XCTAssertEqual(limits.callsRemaining(tier: .fast, used: 999), 0, "Should not go negative")
    }

    func testLimitForTier() {
        let limits = SubscriptionTier.pro.limits

        XCTAssertEqual(limits.limit(for: .fast), 200)
        XCTAssertEqual(limits.limit(for: .smart), 30)
        XCTAssertEqual(limits.limit(for: .deep), 5)
        XCTAssertEqual(limits.limit(for: .max), 0)
    }

    func testFreeTierZeroSmartCalls() {
        let limits = SubscriptionTier.free.limits
        XCTAssertEqual(limits.callsRemaining(tier: .smart, used: 0), 0)
        XCTAssertEqual(limits.callsRemaining(tier: .deep, used: 0), 0)
        XCTAssertEqual(limits.callsRemaining(tier: .max, used: 0), 0)
    }

    // MARK: - ModelTier Minimum Subscription

    func testModelTierMinimumSubscription() {
        XCTAssertEqual(ModelTier.fast.minimumSubscriptionTier, .free)
        XCTAssertEqual(ModelTier.smart.minimumSubscriptionTier, .pro)
        XCTAssertEqual(ModelTier.deep.minimumSubscriptionTier, .pro)
        XCTAssertEqual(ModelTier.max.minimumSubscriptionTier, .unlimited)
    }

    // MARK: - UserSubscription Decoding

    func testUserSubscriptionDecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "660e8400-e29b-41d4-a716-446655440000",
            "tier": "pro",
            "storekit_product_id": "com.agenthub.pro.monthly",
            "status": "active",
            "trial_active": false,
            "current_period_start": "2026-01-01T00:00:00Z",
            "current_period_end": "2026-02-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sub = try decoder.decode(UserSubscription.self, from: json)

        XCTAssertEqual(sub.tier, "pro")
        XCTAssertEqual(sub.subscriptionTier, .pro)
        XCTAssertEqual(sub.storekitProductId, "com.agenthub.pro.monthly")
        XCTAssertTrue(sub.isActive)
        XCTAssertFalse(sub.trialActive)
        XCTAssertNotNil(sub.currentPeriodStart)
        XCTAssertNotNil(sub.currentPeriodEnd)
    }

    func testUserSubscriptionUnknownTierFallsToFree() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "660e8400-e29b-41d4-a716-446655440000",
            "tier": "super_mega",
            "status": "active",
            "trial_active": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sub = try decoder.decode(UserSubscription.self, from: json)

        XCTAssertEqual(sub.subscriptionTier, .free, "Unknown tier should fallback to free")
    }

    func testUserSubscriptionInactiveStatus() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "660e8400-e29b-41d4-a716-446655440000",
            "tier": "starter",
            "status": "expired",
            "trial_active": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sub = try decoder.decode(UserSubscription.self, from: json)

        XCTAssertFalse(sub.isActive)
    }

    // MARK: - CaseIterable

    func testAllTiersCovered() {
        XCTAssertEqual(SubscriptionTier.allCases.count, 4)
    }

    func testAllModelTiersCovered() {
        XCTAssertEqual(ModelTier.allCases.count, 4)
    }
}
