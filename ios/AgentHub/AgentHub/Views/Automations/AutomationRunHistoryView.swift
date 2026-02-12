import SwiftUI

struct AutomationRunHistoryView: View {
    let automationId: UUID

    @State private var runs: [AutomationRun] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading run history...")
            } else if let error = errorMessage {
                ErrorView(message: error) { loadRuns() }
            } else if runs.isEmpty {
                emptyState
            } else {
                runList
            }
        }
        .navigationTitle("Run History")
        .navigationBarTitleDisplayMode(.inline)
        .task { loadRuns() }
    }

    // MARK: - Run List

    private var runList: some View {
        List {
            ForEach(runs) { run in
                NavigationLink {
                    AutomationRunDetailView(run: run)
                } label: {
                    RunRow(run: run)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await fetchRuns()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No Runs Yet")
                .font(.appTitle)
                .foregroundStyle(.primary)

            Text("This automation hasn't run yet. Runs will appear here once the scheduled time arrives.")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Actions

    private func loadRuns() {
        isLoading = true
        errorMessage = nil

        Task {
            await fetchRuns()
            isLoading = false
        }
    }

    private func fetchRuns() async {
        do {
            runs = try await AutomationRunService.shared.fetchRuns(
                automationId: automationId,
                limit: 50
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Run Row

private struct RunRow: View {
    let run: AutomationRun

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 36, height: 36)
                .background(statusColor.opacity(0.12))
                .cornerRadius(8)

            // Run info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.appSubheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    statusBadge
                }

                HStack(spacing: 12) {
                    if let preview = run.outputPreview {
                        Text(preview)
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(run.totalTokensUsed)", systemImage: "number")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Label(run.durationDisplay, systemImage: "timer")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if run.pushSent {
                        Label("Sent", systemImage: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(run.statusDisplay)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.12))
            .cornerRadius(6)
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AutomationRunHistoryView(automationId: UUID())
    }
}
