import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.brandPrimary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sessionManager.currentUser?.displayName ?? "User")
                                    .font(.appHeadline)
                                Text(sessionManager.currentUser?.email ?? "")
                                    .font(.appCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Subscription
                Section("Subscription") {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        Label("Manage Subscription", systemImage: "creditcard.fill")
                    }
                }

                // AI Keys
                Section("AI API Keys") {
                    NavigationLink {
                        APIKeysView()
                    } label: {
                        Label("Your API Keys (BYOK)", systemImage: "key.fill")
                    }
                }

                // About
                Section("About") {
                    Link(destination: URL(string: "https://agenthub.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://agenthub.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                }

                // Account Actions
                Section {
                    Button {
                        Task { await sessionManager.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }

                    Button {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Account", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // Account deletion flow
                    Task { await sessionManager.signOut() }
                }
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
        }
    }
}
