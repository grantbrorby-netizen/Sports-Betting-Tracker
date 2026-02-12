import SwiftUI

extension Color {
    // MARK: - Brand
    static let brandPrimary = Color(red: 0.25, green: 0.47, blue: 1.0)     // Vibrant blue
    static let brandSecondary = Color(red: 0.56, green: 0.27, blue: 1.0)   // Purple accent
    static let brandGradientStart = Color(red: 0.25, green: 0.47, blue: 1.0)
    static let brandGradientEnd = Color(red: 0.56, green: 0.27, blue: 1.0)

    // MARK: - Tiers
    static let tierFree = Color.gray
    static let tierStarter = Color.blue
    static let tierPro = Color(red: 0.56, green: 0.27, blue: 1.0)
    static let tierUnlimited = Color(red: 1.0, green: 0.6, blue: 0.0)

    // MARK: - Status
    static let statusSuccess = Color.green
    static let statusError = Color.red
    static let statusWarning = Color.orange
    static let statusPending = Color.yellow

    // MARK: - Surfaces
    static let surfaceCard = Color(.systemBackground)
    static let surfaceElevated = Color(.secondarySystemBackground)
    static let surfaceGrouped = Color(.systemGroupedBackground)

    static func tierColor(for tier: SubscriptionTier) -> Color {
        switch tier {
        case .free: return .tierFree
        case .starter: return .tierStarter
        case .pro: return .tierPro
        case .unlimited: return .tierUnlimited
        }
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [.brandGradientStart, .brandGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
