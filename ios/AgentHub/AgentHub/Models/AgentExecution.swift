import Foundation

struct AgentExecution: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let installedAgentId: UUID?
    let templateId: UUID
    let input: [String: String]
    let output: String?
    let provider: String?
    let modelTier: String
    let tokensUsed: Int
    let durationMs: Int?
    let isByok: Bool
    let triggeredBy: String
    let status: ExecutionStatus
    let errorMessage: String?
    let createdAt: Date

    enum ExecutionStatus: String, Codable {
        case pending
        case completed
        case failed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case installedAgentId = "installed_agent_id"
        case templateId = "template_id"
        case input, output, provider
        case modelTier = "model_tier"
        case tokensUsed = "tokens_used"
        case durationMs = "duration_ms"
        case isByok = "is_byok"
        case triggeredBy = "triggered_by"
        case status
        case errorMessage = "error_message"
        case createdAt = "created_at"
    }
}
