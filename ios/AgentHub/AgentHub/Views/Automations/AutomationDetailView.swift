import SwiftUI

struct AutomationDetailView: View {
    @StateObject private var viewModel: AutomationDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    let onChanged: () -> Void

    init(automation: Automation, onChanged: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AutomationDetailViewModel(automation: automation))
        self.onChanged = onChanged
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                scheduleSection
                stepsSection
                actionSection
                runHistorySection
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle(viewModel.automation.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task { await viewModel.toggleEnabled() }
                    } label: {
                        Label(
                            viewModel.automation.isEnabled ? "Disable" : "Enable",
                            systemImage: viewModel.automation.isEnabled ? "pause.circle" : "play.circle"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .confirmationDialog(
            "Delete Automation",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.delete() {
                        onChanged()
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This automation and its run history will be permanently deleted.")
        }
        .task {
            await viewModel.loadRuns()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.automation.name)
                        .font(.appTitle)
                        .foregroundStyle(.primary)

                    Text("Template: \(viewModel.automation.templateId)")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusIndicator
            }

            HStack(spacing: 16) {
                detailPill(
                    icon: "bolt",
                    text: ModelTier(rawValue: viewModel.automation.modelTier)?.displayName ?? viewModel.automation.modelTier
                )

                detailPill(
                    icon: viewModel.automation.isEnabled ? "checkmark.circle.fill" : "xmark.circle",
                    text: viewModel.automation.isEnabled ? "Enabled" : "Disabled"
                )

                if let lastRun = viewModel.automation.lastRunAt {
                    detailPill(
                        icon: "clock",
                        text: lastRun.formatted(.relative(presentation: .named))
                    )
                }
            }
        }
        .cardStyle()
    }

    private var statusIndicator: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            Text(viewModel.automation.statusDisplay)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch viewModel.automation.status {
        case "active": return .statusSuccess
        case "paused": return .statusPending
        case "error": return .statusError
        default: return .secondary
        }
    }

    private func detailPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.surfaceElevated)
        .cornerRadius(6)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Schedule", systemImage: "calendar.badge.clock")
                .sectionHeader()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "repeat")
                        .foregroundStyle(Color.brandPrimary)
                        .font(.body)

                    Text(viewModel.automation.scheduleDescription)
                        .font(.appBody)
                        .foregroundStyle(.primary)
                }

                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                        .font(.body)

                    Text(viewModel.automation.timezone)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }

                if let nextRun = viewModel.automation.nextRunAt {
                    HStack {
                        Image(systemName: "arrow.forward.circle")
                            .foregroundStyle(.secondary)
                            .font(.body)

                        Text("Next run: \(nextRun.formatted(date: .abbreviated, time: .shortened))")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Steps Section

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Agent Chain (\(viewModel.automation.steps.count) step\(viewModel.automation.steps.count == 1 ? "" : "s"))", systemImage: "link")
                .sectionHeader()

            VStack(spacing: 0) {
                ForEach(Array(viewModel.automation.steps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Step \(index + 1)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.brandPrimary)
                                .cornerRadius(4)

                            Text(step.name)
                                .font(.appSubheadline)
                                .foregroundStyle(.primary)
                        }

                        Text(step.systemPrompt)
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)

                        if let maxTokens = step.maxTokens {
                            Text("Max tokens: \(maxTokens)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surfaceCard)

                    if index < viewModel.automation.steps.count - 1 {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.down")
                                .font(.caption)
                                .foregroundStyle(Color.brandPrimary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Delivery", systemImage: "bell.badge")
                .sectionHeader()

            HStack(spacing: 12) {
                Image(systemName: actionIcon)
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.brandPrimary.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(actionLabel)
                        .font(.appSubheadline)
                        .foregroundStyle(.primary)

                    if let pushTitle = viewModel.automation.pushTitle {
                        Text("Title: \(pushTitle)")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .cardStyle()
        }
    }

    private var actionIcon: String {
        switch viewModel.automation.actionType {
        case "push_notification": return "bell.fill"
        case "email": return "envelope.fill"
        case "webhook": return "arrow.up.forward.app"
        default: return "bell.fill"
        }
    }

    private var actionLabel: String {
        switch viewModel.automation.actionType {
        case "push_notification": return "Push Notification"
        case "email": return "Email"
        case "webhook": return "Webhook"
        default: return viewModel.automation.actionType.capitalized
        }
    }

    // MARK: - Run History Section

    private var runHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Run History", systemImage: "clock.arrow.circlepath")
                    .sectionHeader()

                Spacer()

                if viewModel.hasRuns {
                    NavigationLink {
                        AutomationRunHistoryView(automationId: viewModel.automation.id)
                    } label: {
                        Text("See All")
                            .font(.appCaption)
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if viewModel.hasRuns {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentRuns) { run in
                        NavigationLink {
                            AutomationRunDetailView(run: run)
                        } label: {
                            RunHistoryRow(run: run)
                        }
                        .buttonStyle(.plain)

                        if run.id != viewModel.recentRuns.last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .cardStyle()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title3)
                        .foregroundStyle(.tertiary)

                    Text("No runs yet")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .cardStyle()
            }
        }
    }
}

// MARK: - Run History Row

private struct RunHistoryRow: View {
    let run: AutomationRun

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.body)
                .foregroundStyle(statusColor)
                .frame(width: 32, height: 32)
                .background(statusColor.opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.appCaption)
                    .foregroundStyle(.primary)

                if let preview = run.outputPreview {
                    Text(preview)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(run.statusDisplay)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor)

                Text("\(run.totalTokensUsed) tokens")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
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
        AutomationDetailView(
            automation: Automation(
                id: UUID(),
                userId: UUID(),
                name: "Daily News Summary",
                templateId: "news-summary",
                triggerType: "cron",
                cronExpression: "0 7 * * 1,2,3,4,5",
                timezone: "America/New_York",
                steps: [
                    AutomationStep(name: "Fetch News", systemPrompt: "Summarize the top headlines", maxTokens: 1024)
                ],
                inputValues: ["topic": "technology"],
                actionType: "push_notification",
                pushTitle: "Your Daily News",
                modelTier: "fast",
                isEnabled: true,
                lastRunAt: Date().addingTimeInterval(-3600),
                nextRunAt: Date().addingTimeInterval(3600),
                status: "active",
                errorMessage: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            onChanged: {}
        )
    }
}
