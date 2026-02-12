import Foundation

struct InstalledAgent: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let templateId: UUID
    var customName: String?
    var isPinned: Bool
    var sortOrder: Int
    var lastUsedAt: Date?
    let installedAt: Date

    // Joined from agent_templates (populated client-side or via join)
    var template: AgentTemplate?

    var displayName: String {
        customName ?? template?.name ?? "Agent"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case templateId = "template_id"
        case customName = "custom_name"
        case isPinned = "is_pinned"
        case sortOrder = "sort_order"
        case lastUsedAt = "last_used_at"
        case installedAt = "installed_at"
        case template
    }
}
