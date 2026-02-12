import SwiftUI

struct AgentHistoryView: View {
    let installedAgentId: UUID
    @State private var executions: [AgentExecution] = []
    @State private var isLoading = true
    @State private var selectedExecution: AgentExecution?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading history...")
            } else if executions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No history yet")
                        .font(.appSubheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(executions) { execution in
                    Button {
                        selectedExecution = execution
                    } label: {
                        executionRow(execution)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedExecution) { execution in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(execution.output ?? "No output")
                            .font(.appBody)
                            .textSelection(.enabled)
                            .padding()

                        HStack(spacing: 16) {
                            if let provider = execution.provider {
                                Label(provider.capitalized, systemImage: "cpu")
                            }
                            Label("\(execution.tokensUsed) tokens", systemImage: "number")
                            UsageBadge(isByok: execution.isByok)
                        }
                        .font(.caption)
                        .padding(.horizontal)
                    }
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
        .task { await loadHistory() }
    }

    private func executionRow(_ execution: AgentExecution) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ModelTier(rawValue: execution.modelTier)?.iconName ?? "cpu")
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(execution.output?.prefix(80).description ?? "No output")
                    .font(.appCaption)
                    .lineLimit(2)

                Text(execution.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge(execution.status)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusBadge(_ status: AgentExecution.ExecutionStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.weight(.medium))
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.1))
            .cornerRadius(4)
    }

    private func statusColor(_ status: AgentExecution.ExecutionStatus) -> Color {
        switch status {
        case .completed: return .statusSuccess
        case .failed: return .statusError
        case .pending: return .statusPending
        }
    }

    private func loadHistory() async {
        do {
            executions = try await AgentExecutionService.shared.fetchHistory(
                installedAgentId: installedAgentId,
                limit: 50
            )
        } catch {}
        isLoading = false
    }
}
