import SwiftUI

@main
struct AgentHubApp: App {
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .environmentObject(subscriptionViewModel)
                .task {
                    await subscriptionViewModel.loadProducts()
                    await subscriptionViewModel.listenForTransactions()
                }
        }
    }
}
