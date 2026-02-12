import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var installedAgents: [InstalledAgent] = []
    @Published var usage: UsageRecord = .empty
    @Published var isLoading = true
    @Published var errorMessage: String?

    var pinnedAgents: [InstalledAgent] {
        installedAgents.filter { $0.isPinned }
    }

    var recentAgents: [InstalledAgent] {
        installedAgents
            .filter { !$0.isPinned }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let agents = AgentInstallService.shared.fetchInstalledAgents()
            async let todayUsage = UsageTracker.shared.fetchTodayUsage()
            installedAgents = try await agents
            usage = try await todayUsage
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func togglePin(_ agent: InstalledAgent) async {
        let newPinned = !agent.isPinned
        do {
            try await AgentInstallService.shared.togglePin(id: agent.id, isPinned: newPinned)
            if let idx = installedAgents.firstIndex(where: { $0.id == agent.id }) {
                installedAgents[idx].isPinned = newPinned
            }
            Haptics.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
