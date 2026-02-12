import Foundation

actor APIKeyService {
    static let shared = APIKeyService()

    struct KeyListResponse: Decodable {
        let keys: [UserAPIKey]
    }

    struct KeyResponse: Decodable {
        let key: UserAPIKey
    }

    func fetchKeys() async throws -> [UserAPIKey] {
        let response: KeyListResponse = try await APIClient.shared.get(url: APIEndpoints.userAPIKeys)
        return response.keys
    }

    func addKey(provider: String, apiKey: String) async throws -> UserAPIKey {
        struct AddKeyBody: Encodable {
            let provider: String
            let api_key: String
        }

        let response: KeyResponse = try await APIClient.shared.post(
            url: APIEndpoints.userAPIKeys,
            body: AddKeyBody(provider: provider, api_key: apiKey)
        )
        return response.key
    }

    func deleteKey(id: UUID) async throws {
        var components = URLComponents(url: APIEndpoints.userAPIKeys, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: id.uuidString)]

        let _: EmptyResponse = try await APIClient.shared.request(
            url: components.url!,
            method: "DELETE"
        )
    }
}
