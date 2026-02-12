import Foundation

@MainActor
class AgentDetailViewModel: ObservableObject {
    @Published var isInstalling = false
    @Published var isInstalled = false
    @Published var installedAgent: InstalledAgent?
    @Published var errorMessage: String?

    let template: AgentTemplate

    init(template: AgentTemplate) {
        self.template = template
        self.isInstalled = template.isInstalled ?? false
    }

    func install() async {
        isInstalling = true
        errorMessage = nil
        do {
            installedAgent = try await AgentInstallService.shared.installAgent(templateId: template.id)
            isInstalled = true
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
        isInstalling = false
    }

    func uninstall() async {
        guard let agent = installedAgent else { return }
        do {
            try await AgentInstallService.shared.uninstallAgent(id: agent.id)
            isInstalled = false
            installedAgent = nil
            Haptics.medium()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
