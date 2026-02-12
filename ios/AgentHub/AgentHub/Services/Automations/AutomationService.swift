import Foundation

actor AutomationService {
    static let shared = AutomationService()

    // MARK: - Request/Response Types

    struct AutomationsResponse: Decodable {
        let automations: [Automation]
    }

    struct AutomationResponse: Decodable {
        let automation: Automation
    }

    struct CreateAutomationBody: Encodable {
        let name: String
        let template_id: String
        let trigger_type: String
        let cron_expression: String
        let timezone: String
        let steps: [StepBody]
        let input_values: [String: String]
        let action_type: String
        let push_title: String?
        let model_tier: String

        struct StepBody: Encodable {
            let name: String
            let system_prompt: String
            let max_tokens: Int?
        }
    }

    struct UpdateAutomationBody: Encodable {
        let name: String?
        let cron_expression: String?
        let timezone: String?
        let steps: [CreateAutomationBody.StepBody]?
        let input_values: [String: String]?
        let action_type: String?
        let push_title: String?
        let model_tier: String?
        let is_enabled: Bool?
    }

    struct ToggleBody: Encodable {
        let is_enabled: Bool
    }

    // MARK: - Fetch All Automations

    func fetchAutomations() async throws -> [Automation] {
        let response: AutomationsResponse = try await APIClient.shared.get(
            url: APIEndpoints.automations
        )
        return response.automations
    }

    // MARK: - Create Automation

    func createAutomation(
        name: String,
        templateId: String,
        cronExpression: String,
        timezone: String,
        steps: [AutomationStep],
        inputValues: [String: String],
        actionType: String,
        pushTitle: String?,
        modelTier: String
    ) async throws -> Automation {
        let body = CreateAutomationBody(
            name: name,
            template_id: templateId,
            trigger_type: "cron",
            cron_expression: cronExpression,
            timezone: timezone,
            steps: steps.map {
                CreateAutomationBody.StepBody(
                    name: $0.name,
                    system_prompt: $0.systemPrompt,
                    max_tokens: $0.maxTokens
                )
            },
            input_values: inputValues,
            action_type: actionType,
            push_title: pushTitle,
            model_tier: modelTier
        )

        let response: AutomationResponse = try await APIClient.shared.post(
            url: APIEndpoints.automations,
            body: body
        )
        return response.automation
    }

    // MARK: - Update Automation

    func updateAutomation(
        id: UUID,
        name: String? = nil,
        cronExpression: String? = nil,
        timezone: String? = nil,
        steps: [AutomationStep]? = nil,
        inputValues: [String: String]? = nil,
        actionType: String? = nil,
        pushTitle: String? = nil,
        modelTier: String? = nil,
        isEnabled: Bool? = nil
    ) async throws -> Automation {
        let url = APIEndpoints.automations.appendingPathComponent(id.uuidString)

        let body = UpdateAutomationBody(
            name: name,
            cron_expression: cronExpression,
            timezone: timezone,
            steps: steps?.map {
                CreateAutomationBody.StepBody(
                    name: $0.name,
                    system_prompt: $0.systemPrompt,
                    max_tokens: $0.maxTokens
                )
            },
            input_values: inputValues,
            action_type: actionType,
            push_title: pushTitle,
            model_tier: modelTier,
            is_enabled: isEnabled
        )

        let response: AutomationResponse = try await APIClient.shared.request(
            url: url,
            method: "PATCH",
            body: body
        )
        return response.automation
    }

    // MARK: - Toggle Automation

    func toggleAutomation(id: UUID, enabled: Bool) async throws -> Automation {
        let url = APIEndpoints.automations.appendingPathComponent(id.uuidString)

        let response: AutomationResponse = try await APIClient.shared.request(
            url: url,
            method: "PATCH",
            body: ToggleBody(is_enabled: enabled)
        )
        return response.automation
    }

    // MARK: - Delete Automation

    func deleteAutomation(id: UUID) async throws {
        let url = APIEndpoints.automations.appendingPathComponent(id.uuidString)

        let _: EmptyResponse = try await APIClient.shared.request(
            url: url,
            method: "DELETE"
        )
    }
}
