import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 8) {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.brandGradient)
                        Text("AgentHub")
                            .font(.appLargeTitle)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                    // Apple Sign In (prominent)
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)

                    dividerWithText("or sign in with email")

                    // Email/Password
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.surfaceElevated)
                            .cornerRadius(10)

                        SecureField("Password", text: $password)
                            .textContentType(.password)
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
                        signInWithEmail()
                    } label: {
                        Text("Sign In")
                    }
                    .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    HStack {
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        Spacer()
                        Button("Create Account") {
                            showSignUp = true
                        }
                    }
                    .font(.appSubheadline)
                    .foregroundStyle(Color.brandPrimary)
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private func dividerWithText(_ text: String) -> some View {
        HStack {
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
            Text(text).font(.appCaption).foregroundStyle(.secondary)
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
        }
    }

    private func signInWithEmail() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let (accessToken, refreshToken, user) = try await AuthService.shared.signIn(email: email, password: password)
                await sessionManager.signIn(accessToken: accessToken, refreshToken: refreshToken, user: user)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        // Apple Sign In handling will use Supabase Auth
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                errorMessage = "Failed to get Apple credentials"
                return
            }
            isLoading = true
            Task {
                do {
                    let (accessToken, refreshToken, user) = try await AuthService.shared.signInWithApple(idToken: tokenString, nonce: "")
                    await sessionManager.signIn(accessToken: accessToken, refreshToken: refreshToken, user: user)
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
