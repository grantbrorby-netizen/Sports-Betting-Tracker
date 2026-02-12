import Foundation

struct Automation: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let templateId: String
    let triggerType: String
    let cronExpression: String
    let timezone: String
    let steps: [AutomationStep]
    let inputValues: [String: String]
    let actionType: String
    let pushTitle: String?
    let modelTier: String
    var isEnabled: Bool
    let lastRunAt: Date?
    let nextRunAt: Date?
    let status: String
    let errorMessage: String?
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Computed Properties

    var isActive: Bool {
        isEnabled && status != "error"
    }

    var statusDisplay: String {
        switch status {
        case "active": return "Active"
        case "paused": return "Paused"
        case "error": return "Error"
        case "disabled": return "Disabled"
        default: return status.capitalized
        }
    }

    var scheduleDescription: String {
        parseCronExpression(cronExpression)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case templateId = "template_id"
        case triggerType = "trigger_type"
        case cronExpression = "cron_expression"
        case timezone
        case steps
        case inputValues = "input_values"
        case actionType = "action_type"
        case pushTitle = "push_title"
        case modelTier = "model_tier"
        case isEnabled = "is_enabled"
        case lastRunAt = "last_run_at"
        case nextRunAt = "next_run_at"
        case status
        case errorMessage = "error_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Cron Parser

    private func parseCronExpression(_ cron: String) -> String {
        let parts = cron.split(separator: " ").map(String.init)
        guard parts.count >= 5 else { return cron }

        let minute = parts[0]
        let hour = parts[1]
        let dayOfWeek = parts[4]

        // Parse time
        guard let h = Int(hour), let m = Int(minute) else {
            return cron
        }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current
        var components = DateComponents()
        components.hour = h
        components.minute = m

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = calendar.timeZone

        let timeString: String
        if let date = calendar.date(from: components) {
            timeString = formatter.string(from: date)
        } else {
            timeString = "\(h):\(String(format: "%02d", m))"
        }

        // Parse days
        if dayOfWeek == "*" {
            return "Every day at \(timeString)"
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let dayNumbers = dayOfWeek.split(separator: ",").compactMap { Int($0) }

        if dayNumbers.count == 7 || dayNumbers.isEmpty {
            return "Every day at \(timeString)"
        }

        let weekdays = Set([1, 2, 3, 4, 5])
        let weekends = Set([0, 6])

        if Set(dayNumbers) == weekdays {
            return "Every weekday at \(timeString)"
        }
        if Set(dayNumbers) == weekends {
            return "Every weekend at \(timeString)"
        }

        let dayLabels = dayNumbers
            .filter { $0 >= 0 && $0 < dayNames.count }
            .map { dayNames[$0] }

        if dayLabels.count == 1 {
            return "Every \(dayLabels[0]) at \(timeString)"
        }

        return "\(dayLabels.joined(separator: ", ")) at \(timeString)"
    }
}

// MARK: - AutomationStep

struct AutomationStep: Codable, Hashable {
    let name: String
    let systemPrompt: String
    let maxTokens: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case systemPrompt = "system_prompt"
        case maxTokens = "max_tokens"
    }
}
