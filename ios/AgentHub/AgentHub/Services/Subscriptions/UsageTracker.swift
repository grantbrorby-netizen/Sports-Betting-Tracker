import Foundation

actor UsageTracker {
    static let shared = UsageTracker()

    func fetchTodayUsage() async throws -> UsageRecord {
        let url = AppEnvironment.current.supabaseURL.appendingPathComponent("rest/v1/usage_tracking")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        let today = ISO8601DateFormatter.standard.string(from: Date()).prefix(10)
        components.queryItems = [
            URLQueryItem(name: "date", value: "eq.\(today)"),
            URLQueryItem(name: "limit", value: "1"),
        ]

        let records: [UsageRecord] = try await APIClient.shared.request(url: components.url!)
        return records.first ?? .empty
    }
}
