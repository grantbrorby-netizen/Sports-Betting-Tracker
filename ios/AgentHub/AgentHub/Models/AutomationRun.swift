import Foundation

struct AutomationRun: Codable, Identifiable {
    let id: UUID
    let automationId: UUID
    let startedAt: Date
    let completedAt: Date?
    let status: String
    let errorMessage: String?
    let stepResults: [StepResult]
    let finalOutput: String?
    let totalTokensUsed: Int
    let totalDurationMs: Int?
    let modelTier: String
    let pushSent: Bool

    var statusDisplay: String {
        switch status {
        case "running": return "Running"
        case "completed": return "Completed"
        case "failed": return "Failed"
        default: return status.capitalized
        }
    }

    var isRunning: Bool {
        status == "running"
    }

    var isCompleted: Bool {
        status == "completed"
    }

    var isFailed: Bool {
        status == "failed"
    }

    var durationDisplay: String {
        guard let durationMs = totalDurationMs else { return "--" }
        let seconds = Double(durationMs) / 1000.0
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        }
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return "\(minutes)m \(remainingSeconds)s"
    }

    var outputPreview: String? {
        guard let output = finalOutput else { return nil }
        if output.count <= 100 {
            return output
        }
        return String(output.prefix(100)) + "..."
    }

    enum CodingKeys: String, CodingKey {
        case id
        case automationId = "automation_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case status
        case errorMessage = "error_message"
        case stepResults = "step_results"
        case finalOutput = "final_output"
        case totalTokensUsed = "total_tokens_used"
        case totalDurationMs = "total_duration_ms"
        case modelTier = "model_tier"
        case pushSent = "push_sent"
    }
}

// MARK: - StepResult

struct StepResult: Codable, Hashable {
    let stepName: String
    let output: String
    let tokensUsed: Int
    let durationMs: Int

    enum CodingKeys: String, CodingKey {
        case stepName = "step_name"
        case output
        case tokensUsed = "tokens_used"
        case durationMs = "duration_ms"
    }
}
