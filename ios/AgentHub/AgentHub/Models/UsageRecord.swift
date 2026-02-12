import Foundation

struct UsageRecord: Codable {
    let userId: UUID
    let date: String
    let fastCalls: Int
    let smartCalls: Int
    let deepCalls: Int
    let maxCalls: Int
    let totalTokens: Int
    let byokCalls: Int
    let automationCalls: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case fastCalls = "fast_calls"
        case smartCalls = "smart_calls"
        case deepCalls = "deep_calls"
        case maxCalls = "max_calls"
        case totalTokens = "total_tokens"
        case byokCalls = "byok_calls"
        case automationCalls = "automation_calls"
    }

    func used(for tier: ModelTier) -> Int {
        switch tier {
        case .fast: return fastCalls
        case .smart: return smartCalls
        case .deep: return deepCalls
        case .max: return maxCalls
        }
    }

    static let empty = UsageRecord(
        userId: UUID(),
        date: "",
        fastCalls: 0,
        smartCalls: 0,
        deepCalls: 0,
        maxCalls: 0,
        totalTokens: 0,
        byokCalls: 0,
        automationCalls: 0
    )
}
