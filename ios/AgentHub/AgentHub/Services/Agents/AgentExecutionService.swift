import Foundation

actor AgentExecutionService {
    static let shared = AgentExecutionService()

    struct ExecutionRequest: Encodable {
        let template_id: String
        let inputs: [String: String]
        let model_tier: String?
        let installed_agent_id: String?
    }

    struct ExecutionResult: Decodable, Equatable {
        let output: String
        let provider: String
        let model: String
        let modelTier: String
        let tokensUsed: Int
        let durationMs: Int
        let isByok: Bool

        enum CodingKeys: String, CodingKey {
            case output, provider, model
            case modelTier = "model_tier"
            case tokensUsed = "tokens_used"
            case durationMs = "duration_ms"
            case isByok = "is_byok"
        }
    }

    func executeAgent(
        templateId: String,
        inputs: [String: String],
        modelTier: ModelTier? = nil,
        installedAgentId: UUID? = nil
    ) async throws -> ExecutionResult {
        let body = ExecutionRequest(
            template_id: templateId,
            inputs: inputs,
            model_tier: modelTier?.rawValue,
            installed_agent_id: installedAgentId?.uuidString
        )

        return try await APIClient.shared.post(
            url: APIEndpoints.aiBroker,
            body: body
        )
    }

    func fetchHistory(
        installedAgentId: UUID? = nil,
        limit: Int = 20
    ) async throws -> [AgentExecution] {
        let url = AppEnvironment.current.supabaseURL.appendingPathComponent("rest/v1/agent_executions")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]

        if let agentId = installedAgentId {
            queryItems.append(URLQueryItem(name: "installed_agent_id", value: "eq.\(agentId.uuidString)"))
        }

        components.queryItems = queryItems
        return try await APIClient.shared.request(url: components.url!)
    }
}
