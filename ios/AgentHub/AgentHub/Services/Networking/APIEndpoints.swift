import Foundation

enum APIEndpoints {
    static let baseURL = AppEnvironment.current.edgeFunctionBaseURL

    // Agent Registry
    static let agentRegistry = baseURL.appendingPathComponent("agent-registry")

    // AI Broker
    static let aiBroker = baseURL.appendingPathComponent("ai-broker")

    // User API Keys (BYOK)
    static let userAPIKeys = baseURL.appendingPathComponent("user-api-keys")

    // Automations (Week 2)
    static let automations = baseURL.appendingPathComponent("automations")
}
