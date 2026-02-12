import Foundation
import AuthenticationServices

actor AuthService {
    static let shared = AuthService()
    private let supabaseURL = AppEnvironment.current.supabaseURL
    private let supabaseKey = AppEnvironment.current.supabaseAnonKey

    // MARK: - Email/Password Sign Up

    func signUp(email: String, password: String) async throws -> (accessToken: String, refreshToken: String, user: User) {
        let url = supabaseURL.appendingPathComponent("auth/v1/signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError("Sign up failed")
        }

        return try parseAuthResponse(data)
    }

    // MARK: - Email/Password Sign In

    func signIn(email: String, password: String) async throws -> (accessToken: String, refreshToken: String, user: User) {
        let url = supabaseURL.appendingPathComponent("auth/v1/token")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "password")]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.unauthorized
        }

        return try parseAuthResponse(data)
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async throws -> (accessToken: String, refreshToken: String, user: User) {
        let url = supabaseURL.appendingPathComponent("auth/v1/token")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "provider": "apple",
            "id_token": idToken,
            "nonce": nonce,
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError("Apple Sign In failed")
        }

        return try parseAuthResponse(data)
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        let url = supabaseURL.appendingPathComponent("auth/v1/recover")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")

        let body = ["email": email]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError("Password reset failed")
        }
    }

    // MARK: - Parse Auth Response

    private func parseAuthResponse(_ data: Data) throws -> (accessToken: String, refreshToken: String, user: User) {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let accessToken = json?["access_token"] as? String,
              let refreshToken = json?["refresh_token"] as? String,
              let userJson = json?["user"] as? [String: Any],
              let userId = userJson["id"] as? String,
              let email = userJson["email"] as? String else {
            throw APIError.decodingError(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid auth response"]))
        }

        let user = User(
            id: UUID(uuidString: userId) ?? UUID(),
            email: email,
            displayName: nil,
            authProvider: (userJson["app_metadata"] as? [String: Any])?["provider"] as? String ?? "email",
            trialExpiresAt: nil,
            deviceToken: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        return (accessToken, refreshToken, user)
    }
}
