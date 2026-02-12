import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.appLargeTitle)
                    .padding(.top, 20)

                Text("Start your 7-day free trial of Pro features")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.surfaceElevated)
                        .cornerRadius(10)

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color.surfaceElevated)
                        .cornerRadius(10)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color.surfaceElevated)
                        .cornerRadius(10)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.appCaption)
                        .foregroundStyle(.red)
                }

                Button {
                    signUp()
                } label: {
                    Text("Create Account")
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
                .disabled(isLoading || !isValid)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Check Your Email", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("We sent a confirmation link to \(email)")
        }
    }

    private var isValid: Bool {
        !email.isEmpty && password.count >= 8 && password == confirmPassword
    }

    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let _ = try await AuthService.shared.signUp(email: email, password: password)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
