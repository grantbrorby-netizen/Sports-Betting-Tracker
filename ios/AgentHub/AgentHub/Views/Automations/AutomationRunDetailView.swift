import SwiftUI

struct AutomationRunDetailView: View {
    let run: AutomationRun

    @State private var copiedToClipboard = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusHeader
                timingSection
                stepResultsSection

                if let output = run.finalOutput {
                    finalOutputSection(output)
                }

                if run.isFailed, let error = run.errorMessage {
                    errorSection(error)
                }

                metadataSection
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle("Run Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: statusIcon)
                .font(.system(size: 32))
                .foregroundStyle(statusColor)
                .frame(width: 56, height: 56)
                .background(statusColor.opacity(0.12))
                .cornerRadius(16)

            VStack(alignment: .leading, spacing: 4) {
                Text(run.statusDisplay)
                    .font(.appTitle)
                    .foregroundStyle(.primary)

                Text(run.startedAt.formatted(date: .long, time: .shortened))
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .cardStyle()
    }

    private var statusIcon: String {
        switch run.status {
        case "completed": return "checkmark.circle.fill"
        case "failed": return "xmark.circle.fill"
        case "running": return "arrow.triangle.2.circlepath"
        default: return "circle"
        }
    }

    private var statusColor: Color {
        switch run.status {
        case "completed": return .statusSuccess
        case "failed": return .statusError
        case "running": return .statusPending
        default: return .secondary
        }
    }

    // MARK: - Timing Section

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Timing", systemImage: "timer")
                .sectionHeader()

            HStack(spacing: 0) {
                timingCell(
                    label: "Started",
                    value: run.startedAt.formatted(date: .omitted, time: .standard)
                )

                Divider()
                    .frame(height: 40)

                timingCell(
                    label: "Completed",
                    value: run.completedAt?.formatted(date: .omitted, time: .standard) ?? "--"
                )

                Divider()
                    .frame(height: 40)

                timingCell(
                    label: "Duration",
                    value: run.durationDisplay
                )
            }
            .cardStyle()
        }
    }

    private func timingCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(value)
                .font(.appSubheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Step Results Section

    private var stepResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Step Results (\(run.stepResults.count))", systemImage: "list.number")
                .sectionHeader()

            VStack(spacing: 0) {
                ForEach(Array(run.stepResults.enumerated()), id: \.offset) { index, result in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.brandPrimary)
                                    .cornerRadius(10)

                                Text(result.stepName)
                                    .font(.appSubheadline)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                Label("\(result.tokensUsed)", systemImage: "number")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)

                                Label(formatDuration(result.durationMs), systemImage: "timer")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Text(result.output)
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.surfaceElevated)
                            .cornerRadius(8)
                    }
                    .padding()

                    if index < run.stepResults.count - 1 {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            .background(Color.surfaceCard)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    // MARK: - Final Output Section

    private func finalOutputSection(_ output: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Final Output", systemImage: "doc.text.fill")
                    .sectionHeader()

                Spacer()

                Button {
                    UIPasteboard.general.string = output
                    copiedToClipboard = true
                    Haptics.success()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedToClipboard = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.clipboard")
                        Text(copiedToClipboard ? "Copied" : "Copy")
                    }
                    .font(.appCaption)
                    .foregroundStyle(copiedToClipboard ? .statusSuccess : Color.brandPrimary)
                }
            }

            Text(output)
                .font(.appBody)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.surfaceCard)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    // MARK: - Error Section

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .sectionHeader()
                .foregroundStyle(.statusError)

            HStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.statusError)

                Text(error)
                    .font(.appBody)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.statusError.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.statusError.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Metadata", systemImage: "info.circle")
                .sectionHeader()

            VStack(spacing: 0) {
                metadataRow(label: "Run ID", value: run.id.uuidString.prefix(8) + "...")
                Divider()
                metadataRow(label: "Model Tier", value: ModelTier(rawValue: run.modelTier)?.displayName ?? run.modelTier)
                Divider()
                metadataRow(label: "Total Tokens", value: "\(run.totalTokensUsed)")
                Divider()
                metadataRow(label: "Push Sent", value: run.pushSent ? "Yes" : "No")
                Divider()
                metadataRow(label: "Steps", value: "\(run.stepResults.count)")
            }
            .cardStyle()
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.appSubheadline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private func formatDuration(_ ms: Int) -> String {
        let seconds = Double(ms) / 1000.0
        if seconds < 1 {
            return "\(ms)ms"
        }
        return String(format: "%.1fs", seconds)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AutomationRunDetailView(
            run: AutomationRun(
                id: UUID(),
                automationId: UUID(),
                startedAt: Date().addingTimeInterval(-300),
                completedAt: Date(),
                status: "completed",
                errorMessage: nil,
                stepResults: [
                    StepResult(stepName: "Fetch News", output: "Top headlines: AI advances continue...", tokensUsed: 256, durationMs: 1200),
                    StepResult(stepName: "Summarize", output: "Today's key tech stories focus on...", tokensUsed: 512, durationMs: 2400),
                ],
                finalOutput: "Here is your daily tech news summary:\n\n1. AI continues to advance in coding tasks\n2. New chip architectures announced\n3. Cloud providers expand services",
                totalTokensUsed: 768,
                totalDurationMs: 3600,
                modelTier: "fast",
                pushSent: true
            )
        )
    }
}
