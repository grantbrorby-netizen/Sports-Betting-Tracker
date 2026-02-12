import SwiftUI

struct AddAPIKeyView: View {
    @Environment(\.dismiss) var dismiss
    var onAdded: (UserAPIKey) -> Void

    @State private var selectedProvider = "openai"
    @State private var apiKey = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let providers = [
        ("openai", "OpenAI", "sk-..."),
        ("anthropic", "Anthropic", "sk-ant-..."),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Provider") {
                    Picker("Provider", selection: $selectedProvider) {
                        ForEach(providers, id: \.0) { id, name, _ in
                            Text(name).tag(id)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("API Key") {
                    SecureField(currentPlaceholder, text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .font(.appMonospaced)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.appCaption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        addKey()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text("Add Key")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || apiKey.isEmpty)
                } footer: {
                    Text("Your key will be encrypted and stored securely. We'll validate it with a test API call before saving.")
                }
            }
            .navigationTitle("Add API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var currentPlaceholder: String {
        providers.first { $0.0 == selectedProvider }?.2 ?? "API Key"
    }

    private func addKey() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let key = try await APIKeyService.shared.addKey(
                    provider: selectedProvider,
                    apiKey: apiKey
                )
                onAdded(key)
                Haptics.success()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                Haptics.error()
            }
            isLoading = false
        }
    }
}
