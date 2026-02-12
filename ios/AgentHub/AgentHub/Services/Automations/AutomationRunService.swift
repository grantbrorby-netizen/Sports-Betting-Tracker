import Foundation

actor AutomationRunService {
    static let shared = AutomationRunService()

    struct RunsResponse: Decodable {
        let runs: [AutomationRun]
    }

    func fetchRuns(automationId: UUID, limit: Int = 10) async throws -> [AutomationRun] {
        var components = URLComponents(
            url: APIEndpoints.automationRuns,
            resolvingAgainstBaseURL: false
        )!

        components.queryItems = [
            URLQueryItem(name: "automation_id", value: automationId.uuidString),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "order", value: "started_at.desc"),
        ]

        let response: RunsResponse = try await APIClient.shared.get(url: components.url!)
        return response.runs
    }
}
