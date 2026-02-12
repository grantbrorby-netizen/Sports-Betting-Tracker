import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var displayName: String = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Display Name", text: $displayName)
                    .textContentType(.name)

                HStack {
                    Text("Email")
                    Spacer()
                    Text(sessionManager.currentUser?.email ?? "")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Sign-in Method")
                    Spacer()
                    Text(sessionManager.currentUser?.authProvider.capitalized ?? "Email")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Trial") {
                if let user = sessionManager.currentUser, user.isTrialActive {
                    HStack {
                        Text("Trial Status")
                        Spacer()
                        Text("\(user.trialDaysRemaining) days remaining")
                            .foregroundStyle(Color.tierPro)
                    }
                } else {
                    HStack {
                        Text("Trial Status")
                        Spacer()
                        Text("Expired")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("Save Changes") {
                    saveProfile()
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = sessionManager.currentUser?.displayName ?? ""
        }
    }

    private func saveProfile() {
        isSaving = true
        // Save to Supabase profiles table
        Task {
            // Profile update via REST API
            isSaving = false
        }
    }
}
