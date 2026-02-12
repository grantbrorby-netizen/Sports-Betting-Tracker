import SwiftUI

struct AgentResultView: View {
    let result: AgentExecutionService.ExecutionResult
    var onRunAgain: (() -> Void)?

    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Result")
                    .font(.appHeadline)
                Spacer()
                UsageBadge(isByok: result.isByok)
            }

            Divider()

            // Output text
            Text(result.output)
                .font(.appBody)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surfaceElevated)
                .cornerRadius(10)

            // Meta info
            HStack(spacing: 16) {
                Label(result.provider.capitalized, systemImage: "cpu")
                Label("\(result.tokensUsed) tokens", systemImage: "number")
                Label("\(result.durationMs)ms", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Actions
            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = result.output
                    showCopied = true
                    Haptics.light()
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        showCopied = false
                    }
                } label: {
                    Label(showCopied ? "Copied!" : "Copy", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(SecondaryButtonStyle())

                ShareLink(item: result.output) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())

                if let onRunAgain = onRunAgain {
                    Button(action: onRunAgain) {
                        Label("Run Again", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .cardStyle()
    }
}
