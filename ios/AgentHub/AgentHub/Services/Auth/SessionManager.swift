import Foundation
import SwiftUI

@MainActor
class SessionManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true

    init() {
        Task {
            await checkSession()
        }
    }

    func checkSession() async {
        let token = await KeychainManager.shared.getAccessToken()
        isAuthenticated = token != nil
        isLoading = false
    }

    func signIn(accessToken: String, refreshToken: String, user: User) async {
        await KeychainManager.shared.saveAccessToken(accessToken)
        await KeychainManager.shared.saveRefreshToken(refreshToken)
        currentUser = user
        isAuthenticated = true
    }

    func signOut() async {
        await KeychainManager.shared.clearAll()
        currentUser = nil
        isAuthenticated = false
    }
}
