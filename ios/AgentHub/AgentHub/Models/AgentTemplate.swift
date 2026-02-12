import Foundation

struct AgentTemplate: Codable, Identifiable, Hashable {
    let id: UUID
    let templateId: String
    let name: String
    let description: String
    let category: String
    let iconName: String
    let systemPrompt: String
    let inputSchema: [AgentInputField]
    let outputFormat: String
    let defaultModelTier: String
    let requiresVision: Bool
    let maxTokens: Int
    let temperature: Double
    let isFeatured: Bool
    let isPublic: Bool
    let version: String
    let author: String
    let createdAt: Date

    // Enriched by registry (not in DB)
    var isInstalled: Bool?

    var categoryDisplayName: String {
        category.capitalized
    }

    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case name, description, category
        case iconName = "icon_name"
        case systemPrompt = "system_prompt"
        case inputSchema = "input_schema"
        case outputFormat = "output_format"
        case defaultModelTier = "default_model_tier"
        case requiresVision = "requires_vision"
        case maxTokens = "max_tokens"
        case temperature
        case isFeatured = "is_featured"
        case isPublic = "is_public"
        case version, author
        case createdAt = "created_at"
        case isInstalled = "is_installed"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AgentTemplate, rhs: AgentTemplate) -> Bool {
        lhs.id == rhs.id
    }
}
