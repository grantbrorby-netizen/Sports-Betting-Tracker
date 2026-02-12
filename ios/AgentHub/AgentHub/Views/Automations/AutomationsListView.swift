import SwiftUI

struct AutomationsListView: View {
    @StateObject private var viewModel = AutomationsViewModel()
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading automations...")
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task { await viewModel.loadAutomations() }
                    }
                } else if viewModel.hasAutomations {
                    automationsList
                } else {
                    emptyState
                }
            }
            .navigationTitle("Automations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSheet = true
                        Haptics.light()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateAutomationView {
                    Task { await viewModel.loadAutomations() }
                }
            }
        }
        .task {
            await viewModel.loadAutomations()
        }
    }

    // MARK: - Automations List

    private var automationsList: some View {
        List {
            if !viewModel.activeAutomations.isEmpty {
                Section {
                    ForEach(viewModel.activeAutomations) { automation in
                        NavigationLink(value: automation.id) {
                            AutomationRowView(
                                automation: automation,
                                onToggle: { Task { await viewModel.toggleEnabled(automation) } }
                            )
                        }
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { viewModel.activeAutomations[$0] }
                        for automation in toDelete {
                            Task { await viewModel.delete(automation) }
                        }
                    }
                } header: {
                    Label("Active", systemImage: "bolt.fill")
                        .font(.appCaption)
                }
            }

            if !viewModel.inactiveAutomations.isEmpty {
                Section {
                    ForEach(viewModel.inactiveAutomations) { automation in
                        NavigationLink(value: automation.id) {
                            AutomationRowView(
                                automation: automation,
                                onToggle: { Task { await viewModel.toggleEnabled(automation) } }
                            )
                        }
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { viewModel.inactiveAutomations[$0] }
                        for automation in toDelete {
                            Task { await viewModel.delete(automation) }
                        }
                    }
                } header: {
                    Label("Inactive", systemImage: "moon.fill")
                        .font(.appCaption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadAutomations()
        }
        .navigationDestination(for: UUID.self) { automationId in
            if let automation = viewModel.automations.first(where: { $0.id == automationId }) {
                AutomationDetailView(automation: automation) {
                    Task { await viewModel.loadAutomations() }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary.opacity(0.6))

            Text("No Automations Yet")
                .font(.appTitle)
                .foregroundStyle(.primary)

            Text("Create automated agent chains that run on a schedule and deliver results via push notification.")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showCreateSheet = true
                Haptics.light()
            } label: {
                Text("Create Automation")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Automation Row View

private struct AutomationRowView: View {
    let automation: Automation
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(automation.name)
                    .font(.appSubheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(automation.scheduleDescription)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    statusBadge

                    if let nextRun = automation.nextRunAt {
                        Text("Next: \(nextRun, style: .relative)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { automation.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(Color.brandPrimary)
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(automation.statusDisplay)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.12))
            .cornerRadius(4)
    }

    private var statusColor: Color {
        switch automation.status {
        case "active": return .statusSuccess
        case "paused": return .statusPending
        case "error": return .statusError
        default: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    AutomationsListView()
}
