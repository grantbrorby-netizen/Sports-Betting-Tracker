import Foundation

@MainActor
final class AutomationDetailViewModel: ObservableObject {
    @Published var automation: Automation
    @Published var runs: [AutomationRun] = []
    @Published var isLoading = false
    @Published var isTogglingEnabled = false
    @Published var errorMessage: String?

    var recentRuns: [AutomationRun] {
        Array(runs.prefix(10))
    }

    var hasRuns: Bool {
        !runs.isEmpty
    }

    var lastRunStatus: String? {
        runs.first?.statusDisplay
    }

    init(automation: Automation) {
        self.automation = automation
    }

    // MARK: - Load Runs

    func loadRuns() async {
        isLoading = true
        errorMessage = nil

        do {
            runs = try await AutomationRunService.shared.fetchRuns(
                automationId: automation.id,
                limit: 10
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Toggle Enabled

    func toggleEnabled() async {
        isTogglingEnabled = true
        let newEnabled = !automation.isEnabled

        // Optimistic update
        automation.isEnabled = newEnabled

        do {
            automation = try await AutomationService.shared.toggleAutomation(
                id: automation.id,
                enabled: newEnabled
            )
            Haptics.success()
        } catch {
            automation.isEnabled = !newEnabled
            errorMessage = error.localizedDescription
            Haptics.error()
        }

        isTogglingEnabled = false
    }

    // MARK: - Delete

    func delete() async -> Bool {
        do {
            try await AutomationService.shared.deleteAutomation(id: automation.id)
            Haptics.success()
            return true
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
            return false
        }
    }
}
