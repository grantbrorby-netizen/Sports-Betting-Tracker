import SwiftUI

struct CreateAutomationView: View {
    @StateObject private var viewModel = CreateAutomationViewModel()
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator
                stepIndicator
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                // Step content
                Group {
                    switch viewModel.currentStep {
                    case .selectTemplate:
                        templateSelectionStep
                    case .configureSchedule:
                        scheduleStep
                    case .setInputs:
                        inputsStep
                    case .review:
                        reviewStep
                    }
                }
                .frame(maxHeight: .infinity)

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task {
            await viewModel.loadTemplates()
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(CreateAutomationViewModel.Step.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue
                          ? Color.brandPrimary
                          : Color.surfaceElevated)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Step 1: Template Selection

    private var templateSelectionStep: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading templates...")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.availableTemplates) { template in
                            TemplateSelectionCard(
                                template: template,
                                isSelected: viewModel.selectedTemplate?.id == template.id
                            ) {
                                viewModel.selectTemplate(template)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Step 2: Schedule Configuration

    private var scheduleStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                TriggerConfigView(
                    selectedHour: $viewModel.selectedHour,
                    selectedMinute: $viewModel.selectedMinute,
                    selectedDays: $viewModel.selectedDays
                )

                // Schedule preview
                VStack(spacing: 8) {
                    Label("Preview", systemImage: "eye")
                        .sectionHeader()

                    Text(viewModel.schedulePreview)
                        .font(.appBody)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                }

                // Timezone
                VStack(alignment: .leading, spacing: 8) {
                    Label("Timezone", systemImage: "globe")
                        .sectionHeader()

                    Text(viewModel.timezone)
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Step 3: Input Values

    private var inputsStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let template = viewModel.selectedTemplate {
                    // Agent chain builder
                    AgentChainBuilderView(steps: $viewModel.steps)

                    Divider()
                        .padding(.vertical, 4)

                    // Template input fields
                    if !template.inputSchema.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Input Values", systemImage: "text.badge.plus")
                                .sectionHeader()

                            ForEach(template.inputSchema) { field in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(field.label)
                                            .font(.appSubheadline)
                                            .foregroundStyle(.primary)

                                        if field.required {
                                            Text("*")
                                                .foregroundStyle(.statusError)
                                        }
                                    }

                                    TextField(
                                        field.placeholder ?? field.label,
                                        text: Binding(
                                            get: { viewModel.inputValues[field.id] ?? "" },
                                            set: { viewModel.inputValues[field.id] = $0 }
                                        )
                                    )
                                    .textFieldStyle(.roundedBorder)
                                    .font(.appBody)
                                }
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // Model tier picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Model Tier", systemImage: "cpu")
                            .sectionHeader()

                        Picker("Model Tier", selection: $viewModel.modelTier) {
                            ForEach(ModelTier.allCases, id: \.rawValue) { tier in
                                Label(tier.displayName, systemImage: tier.iconName)
                                    .tag(tier.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    Text("No template selected")
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Label("Automation Name", systemImage: "pencil")
                        .sectionHeader()

                    TextField("Enter a name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .font(.appBody)
                }

                // Summary card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Summary", systemImage: "doc.text")
                        .sectionHeader()

                    VStack(alignment: .leading, spacing: 10) {
                        reviewRow(icon: "rectangle.stack", label: "Template", value: viewModel.selectedTemplate?.name ?? "--")
                        reviewRow(icon: "calendar.badge.clock", label: "Schedule", value: viewModel.schedulePreview)
                        reviewRow(icon: "globe", label: "Timezone", value: viewModel.timezone)
                        reviewRow(icon: "cpu", label: "Model", value: ModelTier(rawValue: viewModel.modelTier)?.displayName ?? viewModel.modelTier)
                        reviewRow(icon: "link", label: "Steps", value: "\(viewModel.steps.count)")
                        reviewRow(icon: "bell.fill", label: "Delivery", value: viewModel.actionType == "push_notification" ? "Push Notification" : viewModel.actionType)
                    }
                    .cardStyle()
                }

                // Action type
                VStack(alignment: .leading, spacing: 8) {
                    Label("Delivery Method", systemImage: "paperplane")
                        .sectionHeader()

                    Picker("Action", selection: $viewModel.actionType) {
                        Text("Push Notification").tag("push_notification")
                        Text("Email").tag("email")
                    }
                    .pickerStyle(.segmented)

                    if viewModel.actionType == "push_notification" {
                        TextField("Push notification title (optional)", text: $viewModel.pushTitle)
                            .textFieldStyle(.roundedBorder)
                            .font(.appBody)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func reviewRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.appCaption)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.appSubheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if !viewModel.isFirstStep {
                Button("Back") {
                    viewModel.goToPreviousStep()
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            if viewModel.isLastStep {
                Button {
                    Task {
                        if await viewModel.save() != nil {
                            onCreated()
                            dismiss()
                        }
                    }
                } label: {
                    Text("Create Automation")
                }
                .buttonStyle(PrimaryButtonStyle(
                    isLoading: viewModel.isSaving,
                    isDisabled: !viewModel.canProceedToNext
                ))
                .disabled(!viewModel.canProceedToNext || viewModel.isSaving)
            } else {
                Button("Next") {
                    viewModel.goToNextStep()
                }
                .buttonStyle(PrimaryButtonStyle(isDisabled: !viewModel.canProceedToNext))
                .disabled(!viewModel.canProceedToNext)
            }
        }
    }
}

// MARK: - Template Selection Card

private struct TemplateSelectionCard: View {
    let template: AgentTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                IconBadgeView(iconName: template.iconName, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.appSubheadline)
                        .foregroundStyle(.primary)

                    Text(template.description)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.brandPrimary)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(isSelected ? Color.brandPrimary.opacity(0.06) : Color.surfaceCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CreateAutomationView(onCreated: {})
}
