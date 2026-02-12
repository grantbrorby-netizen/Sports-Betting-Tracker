import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    func loadProfile(from user: User?) {
        displayName = user?.displayName ?? ""
    }

    func saveProfile() async {
        isSaving = true
        // Update profile via Supabase REST API
        isSaving = false
    }
}
