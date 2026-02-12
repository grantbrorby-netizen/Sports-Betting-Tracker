import SwiftUI

struct AgentUsageView: View {
    @StateObject private var viewModel: AgentUsageViewModel
    @EnvironmentObject var subscriptionVM: SubscriptionViewModel

    let template: AgentTemplate
    let installedAgentId: UUID?

    init(template: AgentTemplate, installedAgentId: UUID? = nil) {
        self.template = template
        self.installedAgentId = installedAgentId
        _viewModel = StateObject(wrappedValue: AgentUsageViewModel(
            template: template,
            installedAgentId: installedAgentId
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    IconBadgeView(iconName: template.iconName, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.appTitle)
                        Text(template.category.capitalized)
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Dynamic Form
                VStack(spacing: 16) {
                    ForEach(template.inputSchema) { field in
                        dynamicField(field)
                    }
                }
                .padding(.horizontal)

                // Model Tier Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Model")
                        .font(.appSubheadline)
                        .foregroundStyle(.secondary)

                    Picker("Model Tier", selection: $viewModel.selectedModelTier) {
                        ForEach(ModelTier.allCases, id: \.self) { tier in
                            HStack {
                                Image(systemName: tier.iconName)
                                Text(tier.displayName)
                            }
                            .tag(tier)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.appCaption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // Run Button
                Button {
                    Task { await viewModel.execute() }
                } label: {
                    Text(viewModel.isExecuting ? "Running..." : "Run Agent")
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: viewModel.isExecuting, isDisabled: !viewModel.canExecute))
                .disabled(!viewModel.canExecute)
                .padding(.horizontal)

                // Result
                if let result = viewModel.result {
                    AgentResultView(result: result, onRunAgain: {
                        viewModel.clearResult()
                    })
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func dynamicField(_ field: AgentInputField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(field.label)
                    .font(.appSubheadline)
                if field.required {
                    Text("*")
                        .foregroundStyle(.red)
                }
            }

            switch field.type {
            case .text:
                TextField(field.placeholder ?? "", text: binding(for: field.id))
                    .textFieldStyle(.roundedBorder)

            case .textarea:
                TextEditor(text: binding(for: field.id))
                    .frame(minHeight: 80, maxHeight: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

            case .select:
                Picker(field.label, selection: binding(for: field.id)) {
                    Text("Select...").tag("")
                    ForEach(field.options ?? [], id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.surfaceElevated)
                .cornerRadius(8)

            case .number:
                TextField(field.placeholder ?? "0", text: binding(for: field.id))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)

            case .toggle:
                Toggle(isOn: toggleBinding(for: field.id)) {
                    EmptyView()
                }

            case .photo:
                Button {
                    // Photo picker - Phase 2 feature
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Add Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.surfaceElevated)
                    .cornerRadius(8)
                }
                .disabled(true)
                .opacity(0.5)
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
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
}
