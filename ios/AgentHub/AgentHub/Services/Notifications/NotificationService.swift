import Foundation
import UserNotifications
import UIKit

final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var deviceToken: String?

    private override init() {
        super.init()
    }

    // MARK: - Request Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                isAuthorized = granted
            }

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            return false
        }
    }

    // MARK: - Check Current Status

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Register Device Token

    func registerDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()

        Task {
            await MainActor.run {
                self.deviceToken = token
            }
            await sendTokenToServer(token)
        }
    }

    private func sendTokenToServer(_ token: String) async {
        struct TokenBody: Encodable {
            let push_token: String
            let platform: String
        }

        let url = AppEnvironment.current.supabaseURL
            .appendingPathComponent("rest/v1/profiles")

        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                url: url,
                method: "PATCH",
                body: TokenBody(push_token: token, platform: "ios")
            )
        } catch {
            // Token registration is best-effort; log but don't throw
        }
    }

    // MARK: - Handle Remote Notification

    func handleRemoteNotification(
        _ userInfo: [AnyHashable: Any],
        completion: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Extract automation run info if present
        if let automationId = userInfo["automation_id"] as? String {
            NotificationCenter.default.post(
                name: .automationRunCompleted,
                object: nil,
                userInfo: ["automation_id": automationId]
            )
        }

        completion(.newData)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let automationRunCompleted = Notification.Name("automationRunCompleted")
}
