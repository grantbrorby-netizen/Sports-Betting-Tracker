import SwiftUI

struct AgentStoreView: View {
    @State private var templates: [AgentTemplate] = []
    @State private var featuredTemplates: [AgentTemplate] = []
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let categories = Constants.agentCategories

    private var filteredTemplates: [AgentTemplate] {
        var result = templates

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query)
                || $0.description.lowercased().contains(query)
                || $0.category.lowercased().contains(query)
            }
        }

        return result
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading agents...")
                } else if let error = errorMessage {
                    ErrorView(message: error) { loadStore() }
                } else {
                    storeContent
                }
            }
            .navigationTitle("Agent Store")
        }
        .searchable(text: $searchText, prompt: "Search agents")
        .task { loadStore() }
    }

    // MARK: - Store Content

    private var storeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if searchText.isEmpty {
                    featuredSection
                }

                categoryChips

                agentGrid
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured")
                .sectionHeader()
                .padding(.horizontal)

            FeaturedAgentBanner(
                templates: featuredTemplates,
                onInstall: installTemplate
            )
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .sectionHeader()
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    categoryChip(title: "All", category: nil)

                    ForEach(categories, id: \.self) { category in
                        categoryChip(title: category.capitalized, category: category)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func categoryChip(title: String, category: String?) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
            Haptics.selection()
        } label: {
            Text(title)
                .font(.appSubheadline)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AnyShapeStyle(Color.brandGradient) : AnyShapeStyle(Color.surfaceElevated))
                .cornerRadius(20)
        }
    }

    // MARK: - Agent Grid

    private var agentGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedCategory?.capitalized ?? "All Agents")
                    .sectionHeader()

                Spacer()

                Text("\(filteredTemplates.count) agents")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if filteredTemplates.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(filteredTemplates) { template in
                        NavigationLink(value: template) {
                            AgentStoreCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(for: AgentTemplate.self) { template in
            AgentDetailView(template: template, onInstall: installTemplate)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("No agents found")
                .font(.appSubheadline)
                .foregroundStyle(.secondary)

            if !searchText.isEmpty {
                Text("Try a different search term")
                    .font(.appCaption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func loadStore() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let allTemplates = AgentRegistryService.shared.fetchTemplates()
                async let featured = AgentRegistryService.shared.fetchFeatured()

                let (fetchedAll, fetchedFeatured) = try await (allTemplates, featured)
                templates = fetchedAll
                featuredTemplates = fetchedFeatured
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func installTemplate(_ template: AgentTemplate) {
        Task {
            do {
                _ = try await AgentInstallService.shared.installAgent(templateId: template.id)
                Haptics.success()

                // Mark as installed locally
                if let index = templates.firstIndex(where: { $0.id == template.id }) {
                    templates[index].isInstalled = true
                }
                if let index = featuredTemplates.firstIndex(where: { $0.id == template.id }) {
                    featuredTemplates[index].isInstalled = true
                }
            } catch {
                Haptics.error()
            }
        }
    }
}

// MARK: - Agent Store Card

private struct AgentStoreCard: View {
    let template: AgentTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                IconBadgeView(iconName: template.iconName, size: 40)

                Spacer()

                if template.isInstalled == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.statusSuccess)
                        .font(.title3)
                }
            }

            Text(template.name)
                .font(.appSubheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(template.description)
                .font(.appCaption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Text(template.categoryDisplayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.surfaceElevated)
                    .cornerRadius(4)

                Spacer()

                Image(systemName: ModelTier(rawValue: template.defaultModelTier)?.iconName ?? "bolt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
        .frame(minHeight: 150)
    }
}

// MARK: - Preview

#Preview {
    AgentStoreView()
}
