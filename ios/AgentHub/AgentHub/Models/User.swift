import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    var displayName: String?
    let authProvider: String
    var trialExpiresAt: Date?
    var deviceToken: String?
    let createdAt: Date
    var updatedAt: Date

    var isTrialActive: Bool {
        guard let expires = trialExpiresAt else { return false }
        return expires > Date()
    }

    var trialDaysRemaining: Int {
        guard let expires = trialExpiresAt else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0)
    }

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case authProvider = "auth_provider"
        case trialExpiresAt = "trial_expires_at"
        case deviceToken = "device_token"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
