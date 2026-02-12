import Foundation

actor AgentInstallService {
    static let shared = AgentInstallService()

    private let supabaseURL = AppEnvironment.current.supabaseURL
    private let supabaseKey = AppEnvironment.current.supabaseAnonKey

    func fetchInstalledAgents() async throws -> [InstalledAgent] {
        let url = supabaseURL.appendingPathComponent("rest/v1/installed_agents")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "*,template:agent_templates(*)"),
            URLQueryItem(name: "order", value: "is_pinned.desc,last_used_at.desc.nullslast"),
        ]

        return try await APIClient.shared.request(url: components.url!)
    }

    func installAgent(templateId: UUID) async throws -> InstalledAgent {
        let url = supabaseURL.appendingPathComponent("rest/v1/installed_agents")

        struct InstallBody: Encodable {
            let template_id: UUID
        }

        return try await APIClient.shared.request(
            url: url,
            method: "POST",
            body: InstallBody(template_id: templateId)
        )
    }

    func uninstallAgent(id: UUID) async throws {
        let url = supabaseURL.appendingPathComponent("rest/v1/installed_agents")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")]

        let _: EmptyResponse = try await APIClient.shared.request(
            url: components.url!,
            method: "DELETE"
        )
    }

    func togglePin(id: UUID, isPinned: Bool) async throws {
        let url = supabaseURL.appendingPathComponent("rest/v1/installed_agents")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")]

        struct PinBody: Encodable {
            let is_pinned: Bool
        }

        let _: EmptyResponse = try await APIClient.shared.request(
            url: components.url!,
            method: "PATCH",
            body: PinBody(is_pinned: isPinned)
        )
    }
}

struct EmptyResponse: Decodable {}
