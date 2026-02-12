import SwiftUI

// MARK: - HomeViewModel (placeholder for future implementation)

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var installedAgents: [InstalledAgent] = []
    @Published var usage: UsageRecord = .empty
    @Published var subscription: UserSubscription?
    @Published var activeAutomations: [Automation] = []
    @Published var isLoading = true
    @Published var error: Error?

    var pinnedAgents: [InstalledAgent] {
        installedAgents
            .filter { $0.isPinned }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
    }

    var recentAgents: [InstalledAgent] {
        installedAgents
            .filter { !$0.isPinned && $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
    }

    var currentTier: SubscriptionTier {
        subscription?.subscriptionTier ?? .free
    }

    var hasAgents: Bool {
        !installedAgents.isEmpty
    }

    var hasActiveAutomations: Bool {
        !activeAutomations.isEmpty
    }

    func loadDashboard() async {
        isLoading = true
        error = nil

        do {
            async let fetchedUsage = UsageTracker.shared.fetchTodayUsage()
            async let fetchedAutomations = AutomationService.shared.fetchAutomations()
            // TODO: Fetch installed agents and subscription from respective services
            usage = try await fetchedUsage
            let allAutomations = try await fetchedAutomations
            activeAutomations = allAutomations.filter { $0.isActive }
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(
                        message: error.localizedDescription,
                        retryAction: { Task { await viewModel.loadDashboard() } }
                    )
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadDashboard()
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                greetingSection

                if let user = sessionManager.currentUser, user.isTrialActive {
                    TrialBannerView(daysRemaining: user.trialDaysRemaining)
                }

                UsageSummaryBar(
                    usage: viewModel.usage,
                    tier: viewModel.currentTier
                )

                if viewModel.hasActiveAutomations {
                    automationsSummarySection
                }

                if viewModel.hasAgents {
                    agentSections
                } else {
                    EmptyStateView()
                        .padding(.top, 24)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .refreshable {
            await viewModel.loadDashboard()
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.appLargeTitle)
                    .foregroundStyle(.primary)

                if let name = sessionManager.currentUser?.displayName {
                    Text(name)
                        .font(.appTitle)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    // MARK: - Automations Summary

    private var automationsSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Automations", systemImage: "clock.badge.checkmark")
                .sectionHeader()

            HStack(spacing: 14) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.brandPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.activeAutomations.count) automation\(viewModel.activeAutomations.count == 1 ? "" : "s") running")
                        .font(.appSubheadline)
                        .foregroundStyle(.primary)

                    if let nextRun = viewModel.activeAutomations
                        .compactMap({ $0.nextRunAt })
                        .sorted()
                        .first {
                        Text("Next run: \(nextRun, style: .relative)")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                NavigationLink {
                    AutomationsListView()
                } label: {
                    Text("View")
                        .font(.appCaption)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Agent Sections

    private var agentSections: some View {
        VStack(spacing: 24) {
            if !viewModel.pinnedAgents.isEmpty {
                pinnedSection
            }

            if !viewModel.recentAgents.isEmpty {
                recentSection
            }
        }
    }

    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pinned", systemImage: "pin.fill")
                .sectionHeader()

            LazyVStack(spacing: 10) {
                ForEach(viewModel.pinnedAgents) { agent in
                    NavigationLink(value: agent) {
                        AgentCardView(agent: agent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: InstalledAgent.self) { agent in
            AgentUsageDestination(agent: agent)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent", systemImage: "clock.fill")
                .sectionHeader()

            LazyVStack(spacing: 10) {
                ForEach(viewModel.recentAgents) { agent in
                    NavigationLink(value: agent) {
                        AgentCardView(agent: agent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Navigation Destination Placeholder

/// Placeholder view for AgentUsageView navigation destination.
/// Replace with actual AgentUsageView once implemented.
private struct AgentUsageDestination: View {
    let agent: InstalledAgent

    var body: some View {
        Text("Agent Usage: \(agent.displayName)")
            .navigationTitle(agent.displayName)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - InstalledAgent Hashable Conformance for NavigationLink

extension InstalledAgent: Hashable {
    static func == (lhs: InstalledAgent, rhs: InstalledAgent) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(SessionManager())
}
