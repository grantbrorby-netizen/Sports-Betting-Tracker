import SwiftUI

struct APIKeysView: View {
    @State private var keys: [UserAPIKey] = []
    @State private var isLoading = true
    @State private var showAddKey = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading keys...")
            } else if keys.isEmpty {
                emptyState
            } else {
                keysList
            }
        }
        .navigationTitle("API Keys")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddKey = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddKey) {
            AddAPIKeyView(onAdded: { key in
                keys.append(key)
            })
        }
        .task { await loadKeys() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("No API Keys")
                .font(.appHeadline)

            Text("Add your own OpenAI or Anthropic API key for unlimited calls on any tier.")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Add API Key") { showAddKey = true }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 200)
        }
    }

    private var keysList: some View {
        List {
            Section {
                ForEach(keys) { key in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key.providerDisplayName)
                                .font(.appHeadline)
                            Text(key.keyHint)
                                .font(.appMonospaced)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if key.isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .onDelete { indexSet in
                    Task { await deleteKeys(at: indexSet) }
                }
            } footer: {
                Text("BYOK calls are unlimited and bypass daily limits on all tiers. Keys are encrypted server-side.")
                    .font(.appCaption)
            }
        }
    }

    private func loadKeys() async {
        do {
            keys = try await APIKeyService.shared.fetchKeys()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteKeys(at offsets: IndexSet) async {
        for index in offsets {
            let key = keys[index]
            do {
                try await APIKeyService.shared.deleteKey(id: key.id)
                keys.remove(at: index)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
