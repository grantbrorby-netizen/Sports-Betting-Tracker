import Foundation

struct UserAPIKey: Codable, Identifiable {
    let id: UUID
    let provider: String
    let keyHint: String
    let isActive: Bool
    let lastUsedAt: Date?
    let createdAt: Date

    var providerDisplayName: String {
        AIProvider(rawValue: provider)?.displayName ?? provider.capitalized
    }

    enum CodingKeys: String, CodingKey {
        case id, provider
        case keyHint = "key_hint"
        case isActive = "is_active"
        case lastUsedAt = "last_used_at"
        case createdAt = "created_at"
    }
}
