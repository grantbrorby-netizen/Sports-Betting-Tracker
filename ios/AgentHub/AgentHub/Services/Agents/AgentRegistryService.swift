import Foundation

actor AgentRegistryService {
    static let shared = AgentRegistryService()

    struct RegistryResponse: Decodable {
        let templates: [AgentTemplate]
        let total: Int
    }

    func fetchTemplates(
        search: String? = nil,
        category: String? = nil,
        featuredOnly: Bool = false
    ) async throws -> [AgentTemplate] {
        var components = URLComponents(url: APIEndpoints.agentRegistry, resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = []

        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if featuredOnly {
            queryItems.append(URLQueryItem(name: "featured", value: "true"))
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        let response: RegistryResponse = try await APIClient.shared.get(url: components.url!)
        return response.templates
    }

    func fetchFeatured() async throws -> [AgentTemplate] {
        try await fetchTemplates(featuredOnly: true)
    }

    func search(query: String) async throws -> [AgentTemplate] {
        try await fetchTemplates(search: query)
    }
}
