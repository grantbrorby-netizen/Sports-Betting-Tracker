import Foundation

@MainActor
final class AutomationsViewModel: ObservableObject {
    @Published var automations: [Automation] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    var activeAutomations: [Automation] {
        automations.filter { $0.isActive }
    }

    var inactiveAutomations: [Automation] {
        automations.filter { !$0.isActive }
    }

    var activeCount: Int {
        activeAutomations.count
    }

    var hasAutomations: Bool {
        !automations.isEmpty
    }

    // MARK: - Load Automations

    func loadAutomations() async {
        isLoading = true
        errorMessage = nil

        do {
            automations = try await AutomationService.shared.fetchAutomations()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Toggle Enabled

    func toggleEnabled(_ automation: Automation) async {
        let newEnabled = !automation.isEnabled

        // Optimistic update
        if let index = automations.firstIndex(where: { $0.id == automation.id }) {
            automations[index].isEnabled = newEnabled
        }

        do {
            let updated = try await AutomationService.shared.toggleAutomation(
                id: automation.id,
                enabled: newEnabled
            )

            if let index = automations.firstIndex(where: { $0.id == automation.id }) {
                automations[index] = updated
            }
            Haptics.success()
        } catch {
            // Revert on failure
            if let index = automations.firstIndex(where: { $0.id == automation.id }) {
                automations[index].isEnabled = !newEnabled
            }
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - Delete Automation

    func delete(_ automation: Automation) async {
        do {
            try await AutomationService.shared.deleteAutomation(id: automation.id)
            automations.removeAll { $0.id == automation.id }
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    func deleteAtOffsets(_ offsets: IndexSet) {
        let toDelete = offsets.compactMap { automations[safe: $0] }
        for automation in toDelete {
            Task { await delete(automation) }
        }
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
