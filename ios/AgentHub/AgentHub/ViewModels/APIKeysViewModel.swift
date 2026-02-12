import Foundation

@MainActor
class APIKeysViewModel: ObservableObject {
    @Published var keys: [UserAPIKey] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    var hasOpenAIKey: Bool {
        keys.contains { $0.provider == "openai" && $0.isActive }
    }

    var hasAnthropicKey: Bool {
        keys.contains { $0.provider == "anthropic" && $0.isActive }
    }

    var hasByokKeys: Bool {
        hasOpenAIKey || hasAnthropicKey
    }

    func load() async {
        isLoading = true
        do {
            keys = try await APIKeyService.shared.fetchKeys()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteKey(_ key: UserAPIKey) async {
        do {
            try await APIKeyService.shared.deleteKey(id: key.id)
            keys.removeAll { $0.id == key.id }
            Haptics.medium()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addKey(_ key: UserAPIKey) {
        keys.removeAll { $0.provider == key.provider }
        keys.append(key)
    }
}
