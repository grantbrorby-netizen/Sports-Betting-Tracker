import SwiftUI

struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(width: 160)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
