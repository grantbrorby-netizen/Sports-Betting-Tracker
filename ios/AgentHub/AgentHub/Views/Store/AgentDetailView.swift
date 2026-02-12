import SwiftUI

struct AgentDetailView: View {
    let template: AgentTemplate
    var onInstall: ((AgentTemplate) -> Void)?

    @State private var isInstalled: Bool
    @State private var isInstalling = false
    @State private var installedAgent: InstalledAgent?
    @State private var showTierGate = false

    // Derived state
    private var modelTier: ModelTier? {
        ModelTier(rawValue: template.defaultModelTier)
    }

    private var requiredSubscriptionTier: SubscriptionTier {
        modelTier?.minimumSubscriptionTier ?? .free
    }

    init(template: AgentTemplate, onInstall: ((AgentTemplate) -> Void)? = nil) {
        self.template = template
        self.onInstall = onInstall
        _isInstalled = State(initialValue: template.isInstalled ?? false)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                Divider().padding(.horizontal)
                descriptionSection
                Divider().padding(.horizontal)
                inputFieldsPreview
                Divider().padding(.horizontal)
                modelTierSection
                actionSection
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            IconBadgeView(
                iconName: template.iconName,
                size: 80,
                backgroundColor: .brandPrimary.opacity(0.12),
                iconColor: .brandPrimary
            )

            Text(template.name)
                .font(.appLargeTitle)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Label(template.categoryDisplayName, systemImage: "tag.fill")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)

                Text("v\(template.version)")
                    .font(.appCaption)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(template.author)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }

            if template.requiresVision {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                    Text("Requires Vision")
                        .font(.appCaption)
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(24)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .sectionHeader()

            Text(template.description)
                .font(.appBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
    }

    // MARK: - Input Fields Preview

    private var inputFieldsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inputs")
                .sectionHeader()

            if template.inputSchema.isEmpty {
                Text("No inputs required")
                    .font(.appCaption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(template.inputSchema) { field in
                    InputFieldPreviewRow(field: field)
                }
            }
        }
        .padding(20)
    }

    // MARK: - Model Tier Info

    private var modelTierSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model")
                .sectionHeader()

            if let tier = modelTier {
                HStack(spacing: 12) {
                    Image(systemName: tier.iconName)
                        .font(.title3)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.brandPrimary.opacity(0.1))
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier.displayName)
                            .font(.appSubheadline)

                        Text(tier.description)
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if requiredSubscriptionTier != .free {
                        TierBadge(tier: requiredSubscriptionTier)
                    }
                }
                .cardStyle()
            }
        }
        .padding(20)
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 12) {
            if showTierGate {
                TierGateView(
                    requiredTier: requiredSubscriptionTier,
                    feature: template.name
                )
            } else if isInstalled {
                NavigationLink {
                    AgentUsageView(
                        template: template,
                        installedAgent: installedAgent
                    )
                } label: {
                    Text("Run Agent")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Installed")
                    .font(.appCaption)
                    .foregroundStyle(Color.statusSuccess)
            } else {
                Button {
                    handleInstall()
                } label: {
                    Text(isInstalling ? "Installing..." : "Get")
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: isInstalling))
                .disabled(isInstalling)
            }
        }
        .padding(20)
    }

    // MARK: - Actions

    private func handleInstall() {
        isInstalling = true
        Haptics.light()

        Task {
            do {
                let installed = try await AgentInstallService.shared.installAgent(templateId: template.id)
                installedAgent = installed
                isInstalled = true
                isInstalling = false
                onInstall?(template)
                Haptics.success()
            } catch {
                isInstalling = false
                Haptics.error()
            }
        }
    }
}

// MARK: - Input Field Preview Row

private struct InputFieldPreviewRow: View {
    let field: AgentInputField

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 24, height: 24)
                .background(Color.brandPrimary.opacity(0.1))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(field.label)
                        .font(.appSubheadline)

                    if field.required {
                        Text("*")
                            .font(.appCaption)
                            .foregroundStyle(.red)
                    }
                }

                Text(fieldTypeDescription)
                    .font(.appCaption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(field.type.rawValue.capitalized)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.surfaceElevated)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch field.type {
        case .text: return "textformat"
        case .textarea: return "doc.text"
        case .select: return "list.bullet"
        case .number: return "number"
        case .toggle: return "switch.2"
        case .photo: return "photo"
        }
    }

    private var fieldTypeDescription: String {
        switch field.type {
        case .text:
            return field.placeholder ?? "Text input"
        case .textarea:
            return field.placeholder ?? "Multi-line text"
        case .select:
            let count = field.options?.count ?? 0
            return "\(count) option\(count == 1 ? "" : "s") available"
        case .number:
            return field.placeholder ?? "Numeric value"
        case .toggle:
            return "On / Off"
        case .photo:
            return "Photo attachment"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentDetailView(
            template: AgentTemplate(
                id: UUID(),
                templateId: "preview-agent",
                name: "Email Composer",
                description: "Compose professional emails with AI assistance. Provide context and the agent will draft clear, effective emails tailored to your tone.",
                category: "writing",
                iconName: "envelope.fill",
                systemPrompt: "",
                inputSchema: [
                    AgentInputField(id: "subject", type: .text, label: "Subject", placeholder: "Email subject", required: true),
                    AgentInputField(id: "context", type: .textarea, label: "Context", placeholder: "What is this email about?", required: true),
                    AgentInputField(id: "tone", type: .select, label: "Tone", required: false, options: ["Professional", "Casual", "Friendly"]),
                ],
                outputFormat: "text",
                defaultModelTier: "fast",
                requiresVision: false,
                maxTokens: 2048,
                temperature: 0.7,
                isFeatured: true,
                isPublic: true,
                version: "1.0",
                author: "AgentHub",
                createdAt: Date(),
                isInstalled: false
            )
        )
    }
}
