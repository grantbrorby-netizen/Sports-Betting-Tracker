import SwiftUI

struct AgentUsageView: View {
    @StateObject private var viewModel: AgentUsageViewModel
    @EnvironmentObject var subscriptionVM: SubscriptionViewModel

    let template: AgentTemplate
    let installedAgent: InstalledAgent?

    @State private var navigateToResult = false

    init(template: AgentTemplate, installedAgent: InstalledAgent? = nil) {
        self.template = template
        self.installedAgent = installedAgent
        _viewModel = StateObject(wrappedValue: AgentUsageViewModel(
            template: template,
            installedAgentId: installedAgent?.id
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                agentHeader
                dynamicForm
                modelTierSelector
                errorBanner
                runButton
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("Run Agent")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            if let result = viewModel.result {
                AgentResultView(
                    agentName: template.name,
                    result: result,
                    onRunAgain: {
                        viewModel.clearResult()
                        navigateToResult = false
                    }
                )
            }
        }
        .onChange(of: viewModel.result) { _, newValue in
            if newValue != nil {
                navigateToResult = true
            }
        }
    }

    // MARK: - Agent Header

    private var agentHeader: some View {
        HStack(spacing: 14) {
            IconBadgeView(iconName: template.iconName, size: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .font(.appTitle)

                Text(template.categoryDisplayName)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let agent = installedAgent {
                NavigationLink {
                    AgentHistoryView(installedAgentId: agent.id)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
    }

    // MARK: - Dynamic Form

    private var dynamicForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inputs")
                .sectionHeader()

            if template.inputSchema.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.statusSuccess)
                    Text("No inputs required. Ready to run.")
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(template.inputSchema) { field in
                    dynamicField(field)
                }
            }
        }
    }

    @ViewBuilder
    private func dynamicField(_ field: AgentInputField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(for: field)

            switch field.type {
            case .text:
                TextField(field.placeholder ?? field.label, text: textBinding(for: field.id))
                    .font(.appBody)
                    .padding(12)
                    .background(Color.surfaceElevated)
                    .cornerRadius(10)

            case .textarea:
                ZStack(alignment: .topLeading) {
                    if (viewModel.formValues[field.id] ?? "").isEmpty {
                        Text(field.placeholder ?? field.label)
                            .font(.appBody)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }

                    TextEditor(text: textBinding(for: field.id))
                        .font(.appBody)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                }
                .frame(minHeight: 100, maxHeight: 200)
                .background(Color.surfaceElevated)
                .cornerRadius(10)

            case .select:
                Menu {
                    ForEach(field.options ?? [], id: \.self) { option in
                        Button(option) {
                            viewModel.formValues[field.id] = option
                            Haptics.selection()
                        }
                    }
                } label: {
                    HStack {
                        let value = viewModel.formValues[field.id] ?? ""
                        Text(value.isEmpty ? (field.placeholder ?? "Select...") : value)
                            .font(.appBody)
                            .foregroundStyle(value.isEmpty ? .tertiary : .primary)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.surfaceElevated)
                    .cornerRadius(10)
                }

            case .number:
                TextField(field.placeholder ?? "0", text: textBinding(for: field.id))
                    .font(.appBody)
                    .keyboardType(.decimalPad)
                    .padding(12)
                    .background(Color.surfaceElevated)
                    .cornerRadius(10)

            case .toggle:
                Toggle(isOn: toggleBinding(for: field.id)) {
                    EmptyView()
                }
                .tint(Color.brandPrimary)

            case .photo:
                Button {
                    // Photo picker integration point (Phase 2)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                            .foregroundStyle(Color.brandPrimary)

                        Text("Tap to add photo")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color.surfaceElevated)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                Color.brandPrimary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [6])
                            )
                    )
                }
            }
        }
    }

    private func fieldLabel(for field: AgentInputField) -> some View {
        HStack(spacing: 4) {
            Text(field.label)
                .font(.appSubheadline)

            if field.required {
                Text("*")
                    .font(.appCaption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Model Tier Selector

    private var modelTierSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Model Tier")
                .sectionHeader()

            VStack(spacing: 0) {
                ForEach(Array(ModelTier.allCases.enumerated()), id: \.element) { index, tier in
                    let isAccessible = isTierAccessible(tier)

                    Button {
                        guard isAccessible else { return }
                        viewModel.selectedModelTier = tier
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tier.iconName)
                                .font(.body)
                                .foregroundStyle(
                                    viewModel.selectedModelTier == tier
                                        ? Color.brandPrimary
                                        : isAccessible ? .primary : .secondary.opacity(0.5)
                                )
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(tier.displayName)
                                    .font(.appSubheadline)
                                    .foregroundStyle(
                                        isAccessible ? .primary : .secondary.opacity(0.5)
                                    )

                                Text(tier.description)
                                    .font(.appCaption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if !isAccessible {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TierBadge(tier: tier.minimumSubscriptionTier)
                            } else if viewModel.selectedModelTier == tier {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            viewModel.selectedModelTier == tier && isAccessible
                                ? Color.brandPrimary.opacity(0.06)
                                : Color.clear
                        )
                    }
                    .disabled(!isAccessible)

                    if index < ModelTier.allCases.count - 1 {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .background(Color.surfaceCard)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.statusError)

                Text(error)
                    .font(.appCaption)
                    .foregroundStyle(Color.statusError)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    withAnimation { viewModel.errorMessage = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color.statusError.opacity(0.08))
            .cornerRadius(10)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Run Button

    private var runButton: some View {
        Button {
            Task { await viewModel.execute() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isExecuting {
                    ProgressView()
                        .tint(.white)
                }
                Text(viewModel.isExecuting ? "Running..." : "Run Agent")
            }
        }
        .buttonStyle(PrimaryButtonStyle(
            isLoading: viewModel.isExecuting,
            isDisabled: !viewModel.canExecute
        ))
        .disabled(!viewModel.canExecute || viewModel.isExecuting)
        .padding(.top, 4)
    }

    // MARK: - Bindings

    private func textBinding(for key: String) -> Binding<String> {
        Binding(
            get: { viewModel.formValues[key] ?? "" },
            set: { viewModel.formValues[key] = $0 }
        )
    }

    private func toggleBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.formValues[key] == "true" },
            set: { viewModel.formValues[key] = $0 ? "true" : "false" }
        )
    }

    private func isTierAccessible(_ tier: ModelTier) -> Bool {
        let required = tier.minimumSubscriptionTier
        let allTiers = SubscriptionTier.allCases
        guard let userIndex = allTiers.firstIndex(of: subscriptionVM.currentTier),
              let requiredIndex = allTiers.firstIndex(of: required) else {
            return false
        }
        return userIndex >= requiredIndex
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentUsageView(
            template: AgentTemplate(
                id: UUID(),
                templateId: "preview-agent",
                name: "Email Composer",
                description: "Compose professional emails with AI.",
                category: "writing",
                iconName: "envelope.fill",
                systemPrompt: "",
                inputSchema: [
                    AgentInputField(id: "subject", type: .text, label: "Subject", placeholder: "Email subject", required: true),
                    AgentInputField(id: "body", type: .textarea, label: "Context", placeholder: "Describe what the email should say...", required: true),
                    AgentInputField(id: "tone", type: .select, label: "Tone", required: false, options: ["Professional", "Casual", "Friendly", "Urgent"]),
                    AgentInputField(id: "wordCount", type: .number, label: "Max Words", placeholder: "200", required: false),
                    AgentInputField(id: "formal", type: .toggle, label: "Formal Signature", required: false, defaultValue: .bool(true)),
                    AgentInputField(id: "photo", type: .photo, label: "Reference Image", required: false),
                ],
                outputFormat: "text",
                defaultModelTier: "fast",
                requiresVision: false,
                maxTokens: 2048,
                temperature: 0.7,
                isFeatured: false,
                isPublic: true,
                version: "1.0",
                author: "AgentHub",
                createdAt: Date()
            )
        )
        .environmentObject(SubscriptionViewModel())
    }
}
