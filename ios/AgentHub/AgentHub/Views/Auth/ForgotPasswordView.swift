import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.appTitle)

                Text("Enter your email and we'll send you a reset link")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.surfaceElevated)
                    .cornerRadius(10)

                if let error = errorMessage {
                    Text(error)
                        .font(.appCaption)
                        .foregroundStyle(.red)
                }

                Button {
                    resetPassword()
                } label: {
                    Text("Send Reset Link")
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
                .disabled(isLoading || email.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Email Sent", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Check \(email) for a password reset link")
            }
        }
    }

    private func resetPassword() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await AuthService.shared.resetPassword(email: email)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
