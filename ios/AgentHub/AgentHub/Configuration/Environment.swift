import Foundation

enum AppEnvironment {
    case development
    case production

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var supabaseURL: URL {
        switch self {
        case .development:
            return URL(string: "https://your-dev-project.supabase.co")!
        case .production:
            return URL(string: "https://your-prod-project.supabase.co")!
        }
    }

    var supabaseAnonKey: String {
        switch self {
        case .development:
            return "your-dev-anon-key"
        case .production:
            return "your-prod-anon-key"
        }
    }

    var edgeFunctionBaseURL: URL {
        supabaseURL.appendingPathComponent("functions/v1")
    }
}
