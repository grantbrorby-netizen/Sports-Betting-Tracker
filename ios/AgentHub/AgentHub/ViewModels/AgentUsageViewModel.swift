import Foundation

@MainActor
class AgentUsageViewModel: ObservableObject {
    @Published var formValues: [String: String] = [:]
    @Published var selectedModelTier: ModelTier = .fast
    @Published var isExecuting = false
    @Published var result: AgentExecutionService.ExecutionResult?
    @Published var errorMessage: String?
    @Published var executionHistory: [AgentExecution] = []

    let template: AgentTemplate
    let installedAgentId: UUID?

    init(template: AgentTemplate, installedAgentId: UUID? = nil) {
        self.template = template
        self.installedAgentId = installedAgentId
        self.selectedModelTier = ModelTier(rawValue: template.defaultModelTier) ?? .fast

        // Pre-fill default values
        for field in template.inputSchema {
            if let defaultValue = field.defaultValue {
                formValues[field.id] = defaultValue.stringValue
            }
        }
    }

    var requiredFieldsMissing: [String] {
        template.inputSchema
            .filter { $0.required }
            .filter { (formValues[$0.id] ?? "").isEmpty }
            .map { $0.label }
    }

    var canExecute: Bool {
        requiredFieldsMissing.isEmpty && !isExecuting
    }

    func execute() async {
        guard canExecute else {
            errorMessage = "Please fill in: \(requiredFieldsMissing.joined(separator: ", "))"
            return
        }

        isExecuting = true
        errorMessage = nil
        result = nil

        do {
            result = try await AgentExecutionService.shared.executeAgent(
                templateId: template.templateId,
                inputs: formValues,
                modelTier: selectedModelTier,
                installedAgentId: installedAgentId
            )
            Haptics.success()
        } catch let error as APIError where error.isRateLimited {
            errorMessage = error.localizedDescription
            Haptics.error()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }

        isExecuting = false
    }

    func loadHistory() async {
        guard let agentId = installedAgentId else { return }
        do {
            executionHistory = try await AgentExecutionService.shared.fetchHistory(
                installedAgentId: agentId,
                limit: 20
            )
        } catch {
            // Non-critical, don't show error
        }
    }

    func clearResult() {
        result = nil
        errorMessage = nil
    }
}
