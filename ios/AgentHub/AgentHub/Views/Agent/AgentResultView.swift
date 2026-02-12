import SwiftUI

struct AgentResultView: View {
    let agentName: String
    let result: AgentExecutionService.ExecutionResult
    var onRunAgain: (() -> Void)?

    @State private var showCopied = false

    private var modelTier: ModelTier? {
        ModelTier(rawValue: result.modelTier)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                outputSection
                metadataSection
                actionButtons
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                UsageBadge(isByok: result.isByok)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.statusSuccess)

                VStack(alignment: .leading, spacing: 2) {
                    Text(agentName)
                        .font(.appHeadline)

                    Text("Completed successfully")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Output

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Output")
                .sectionHeader()

            Text(result.output)
                .font(.appBody)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surfaceElevated)
                .cornerRadius(12)
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .sectionHeader()

            VStack(spacing: 0) {
                metadataRow(
                    icon: "cpu",
                    label: "Provider",
                    value: result.provider.capitalized
                )

                Divider().padding(.leading, 44)

                metadataRow(
                    icon: modelTier?.iconName ?? "bolt",
                    label: "Model Tier",
                    value: modelTier?.displayName ?? result.modelTier.capitalized
                )

                Divider().padding(.leading, 44)

                metadataRow(
                    icon: "number",
                    label: "Tokens Used",
                    value: "\(result.tokensUsed)"
                )

                Divider().padding(.leading, 44)

                metadataRow(
                    icon: "clock",
                    label: "Duration",
                    value: formattedDuration
                )

                if result.isByok {
                    Divider().padding(.leading, 44)

                    metadataRow(
                        icon: "key.fill",
                        label: "API Key",
                        value: "Your Key (BYOK)"
                    )
                }
            }
            .background(Color.surfaceCard)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 24, height: 24)
                .background(Color.brandPrimary.opacity(0.1))
                .cornerRadius(6)

            Text(label)
                .font(.appSubheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.appSubheadline)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }

    private var formattedDuration: String {
        let ms = result.durationMs
        if ms < 1000 {
            return "\(ms)ms"
        } else {
            let seconds = Double(ms) / 1000.0
            return String(format: "%.1fs", seconds)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
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
                    Label(
                        showCopied ? "Copied!" : "Copy",
                        systemImage: showCopied ? "checkmark" : "doc.on.doc"
                    )
                }
                .buttonStyle(SecondaryButtonStyle())

                ShareLink(item: result.output) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            if let onRunAgain {
                Button(action: onRunAgain) {
                    Label("Run Again", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentResultView(
            agentName: "Email Composer",
            result: AgentExecutionService.ExecutionResult(
                output: "Subject: Quarterly Review Meeting\n\nDear Team,\n\nI hope this message finds you well. I'm writing to schedule our quarterly review meeting for next week.\n\nPlease review the attached agenda and confirm your availability by end of day Friday.\n\nBest regards,\nJohn",
                provider: "openai",
                model: "gpt-4o",
                modelTier: "smart",
                tokensUsed: 342,
                durationMs: 2150,
                isByok: false
            ),
            onRunAgain: {}
        )
    }
}
