import Foundation

@MainActor
class AgentStoreViewModel: ObservableObject {
    @Published var allTemplates: [AgentTemplate] = []
    @Published var featuredTemplates: [AgentTemplate] = []
    @Published var searchResults: [AgentTemplate] = []
    @Published var searchText = ""
    @Published var selectedCategory: String?
    @Published var isLoading = true
    @Published var errorMessage: String?

    var isSearching: Bool {
        !searchText.isEmpty
    }

    var categories: [String] {
        Constants.agentCategories
    }

    var displayedTemplates: [AgentTemplate] {
        if isSearching {
            return searchResults
        }
        if let category = selectedCategory {
            return allTemplates.filter { $0.category == category }
        }
        return allTemplates
    }

    func load() async {
        isLoading = true
        do {
            async let all = AgentRegistryService.shared.fetchTemplates()
            async let featured = AgentRegistryService.shared.fetchFeatured()
            allTemplates = try await all
            featuredTemplates = try await featured
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func search() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        do {
            searchResults = try await AgentRegistryService.shared.search(query: searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCategory(_ category: String?) {
        selectedCategory = selectedCategory == category ? nil : category
        Haptics.selection()
    }
}
