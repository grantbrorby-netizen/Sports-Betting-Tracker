import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signIn(sessionManager: SessionManager) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let (accessToken, refreshToken, user) = try await AuthService.shared.signIn(
                email: email, password: password
            )
            await sessionManager.signIn(accessToken: accessToken, refreshToken: refreshToken, user: user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(sessionManager: SessionManager) async {
        guard !email.isEmpty, password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let (accessToken, refreshToken, user) = try await AuthService.shared.signUp(
                email: email, password: password
            )
            await sessionManager.signIn(accessToken: accessToken, refreshToken: refreshToken, user: user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.resetPassword(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
