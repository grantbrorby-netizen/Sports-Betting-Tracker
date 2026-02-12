import Foundation

enum AIProvider: String, Codable, CaseIterable {
    case openai
    case anthropic

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }
}

enum ModelTier: String, Codable, CaseIterable {
    case fast
    case smart
    case deep
    case max

    var displayName: String {
        switch self {
        case .fast: return "Fast"
        case .smart: return "Smart"
        case .deep: return "Deep Reasoning"
        case .max: return "Max Reasoning"
        }
    }

    var description: String {
        switch self {
        case .fast: return "Quick responses for everyday tasks"
        case .smart: return "Advanced analysis and writing"
        case .deep: return "Complex reasoning and analysis"
        case .max: return "Hardest problems, detailed planning"
        }
    }

    var iconName: String {
        switch self {
        case .fast: return "hare.fill"
        case .smart: return "brain"
        case .deep: return "brain.head.profile"
        case .max: return "sparkles"
        }
    }

    /// Minimum tier required to access this model tier
    var minimumSubscriptionTier: SubscriptionTier {
        switch self {
        case .fast: return .free
        case .smart: return .pro
        case .deep: return .pro
        case .max: return .unlimited
        }
    }
}
