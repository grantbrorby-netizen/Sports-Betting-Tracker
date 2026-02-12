import SwiftUI

struct AgentHistoryView: View {
    let installedAgentId: UUID

    @State private var executions: [AgentExecution] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedExecution: AgentExecution?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading history...")
            } else if let error = errorMessage {
                ErrorView(message: error) { loadHistory() }
            } else if executions.isEmpty {
                emptyState
            } else {
                executionList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedExecution) { execution in
            executionDetailSheet(execution)
        }
        .task { loadHistory() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No history yet")
                .font(.appHeadline)
                .foregroundStyle(.secondary)

            Text("Run the agent to see results here")
                .font(.appCaption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Execution List

    private var executionList: some View {
        List(executions) { execution in
            Button {
                selectedExecution = execution
                Haptics.light()
            } label: {
                ExecutionRow(execution: execution)
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
    }

    // MARK: - Detail Sheet

    private func executionDetailSheet(_ execution: AgentExecution) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status header
                    HStack(spacing: 10) {
                        statusIcon(execution.status)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(statusLabel(execution.status))
                                .font(.appHeadline)

                            Text(execution.createdAt, format: .dateTime.month().day().year().hour().minute())
                                .font(.appCaption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        UsageBadge(isByok: execution.isByok)
                    }

                    Divider()

                    // Output
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Output")
                            .sectionHeader()

                        if let output = execution.output {
                            Text(output)
                                .font(.appBody)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surfaceElevated)
                                .cornerRadius(12)
                        } else if let error = execution.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.statusError)
                                Text(error)
                                    .font(.appBody)
                                    .foregroundStyle(Color.statusError)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.statusError.opacity(0.08))
                            .cornerRadius(12)
                        } else {
                            Text("No output available")
                                .font(.appBody)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Divider()

                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .sectionHeader()

                        VStack(spacing: 0) {
                            if let provider = execution.provider {
                                detailRow(icon: "cpu", label: "Provider", value: provider.capitalized)
                                Divider().padding(.leading, 44)
                            }

                            if let tier = ModelTier(rawValue: execution.modelTier) {
                                detailRow(icon: tier.iconName, label: "Model Tier", value: tier.displayName)
                                Divider().padding(.leading, 44)
                            }

                            detailRow(icon: "number", label: "Tokens", value: "\(execution.tokensUsed)")

                            if let durationMs = execution.durationMs {
                                Divider().padding(.leading, 44)
                                let durationStr = durationMs < 1000 ? "\(durationMs)ms" : String(format: "%.1fs", Double(durationMs) / 1000.0)
                                detailRow(icon: "clock", label: "Duration", value: durationStr)
                            }
                        }
                        .background(Color.surfaceCard)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }

                    // Copy / Share
                    if let output = execution.output {
                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = output
                                Haptics.light()
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            ShareLink(item: output) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { selectedExecution = nil }
                }
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
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

    private func statusIcon(_ status: AgentExecution.ExecutionStatus) -> some View {
        Image(systemName: statusIconName(status))
            .font(.title2)
            .foregroundStyle(statusColor(status))
    }

    private func statusIconName(_ status: AgentExecution.ExecutionStatus) -> String {
        switch status {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        }
    }

    private func statusLabel(_ status: AgentExecution.ExecutionStatus) -> String {
        switch status {
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .pending: return "Pending"
        }
    }

    private func statusColor(_ status: AgentExecution.ExecutionStatus) -> Color {
        switch status {
        case .completed: return .statusSuccess
        case .failed: return .statusError
        case .pending: return .statusPending
        }
    }

    // MARK: - Data Loading

    private func loadHistory() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                executions = try await AgentExecutionService.shared.fetchHistory(
                    installedAgentId: installedAgentId,
                    limit: 50
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Execution Row

private struct ExecutionRow: View {
    let execution: AgentExecution

    private var modelTier: ModelTier? {
        ModelTier(rawValue: execution.modelTier)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Model tier icon
            Image(systemName: modelTier?.iconName ?? "cpu")
                .font(.body)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 32, height: 32)
                .background(Color.brandPrimary.opacity(0.1))
                .cornerRadius(8)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(outputPreview)
                    .font(.appSubheadline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text(execution.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if let tier = modelTier {
                        Text(tier.displayName)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Status badge
            statusBadge
        }
        .padding(.vertical, 4)
    }

    private var outputPreview: String {
        if let output = execution.output, !output.isEmpty {
            let cleaned = output.replacingOccurrences(of: "\n", with: " ")
            if cleaned.count > 100 {
                return String(cleaned.prefix(100)) + "..."
            }
            return cleaned
        }
        if execution.status == .failed {
            return execution.errorMessage ?? "Execution failed"
        }
        return "Pending..."
    }

    private var statusBadge: some View {
        Text(execution.status.rawValue.capitalized)
            .font(.caption2.weight(.medium))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.1))
            .cornerRadius(6)
    }

    private var badgeColor: Color {
        switch execution.status {
        case .completed: return .statusSuccess
        case .failed: return .statusError
        case .pending: return .statusPending
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentHistoryView(installedAgentId: UUID())
    }
}
