import SwiftUI

struct AgentChainBuilderView: View {
    @Binding var steps: [AutomationStep]

    private let maxSteps = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Agent Chain", systemImage: "link")
                .sectionHeader()

            // Step cards
            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    StepCard(
                        stepNumber: index + 1,
                        step: step,
                        canRemove: steps.count > 1,
                        onRemove: { removeStep(at: index) },
                        onUpdate: { updated in updateStep(at: index, with: updated) }
                    )

                    if index < steps.count - 1 {
                        chainConnector
                    }
                }
            }

            // Add step button
            if steps.count < maxSteps {
                Button {
                    addStep()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)

                        Text("Add Step")
                            .font(.appSubheadline)
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brandPrimary.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                Color.brandPrimary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [6, 3])
                            )
                    )
                }
                .padding(.top, 4)
            } else {
                Text("Maximum \(maxSteps) steps reached")
                    .font(.appCaption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Chain Connector

    private var chainConnector: some View {
        HStack {
            Spacer()
            VStack(spacing: 2) {
                Rectangle()
                    .fill(Color.brandPrimary.opacity(0.4))
                    .frame(width: 2, height: 8)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.brandPrimary)

                Rectangle()
                    .fill(Color.brandPrimary.opacity(0.4))
                    .frame(width: 2, height: 8)
            }
            Spacer()
        }
    }

    // MARK: - Actions

    private func addStep() {
        let newStep = AutomationStep(
            name: "Step \(steps.count + 1)",
            systemPrompt: "",
            maxTokens: nil
        )
        steps.append(newStep)
        Haptics.light()
    }

    private func removeStep(at index: Int) {
        guard steps.count > 1 else { return }
        steps.remove(at: index)
        Haptics.light()
    }

    private func updateStep(at index: Int, with step: AutomationStep) {
        guard index < steps.count else { return }
        steps[index] = step
    }
}

// MARK: - Step Card

private struct StepCard: View {
    let stepNumber: Int
    let step: AutomationStep
    let canRemove: Bool
    let onRemove: () -> Void
    let onUpdate: (AutomationStep) -> Void

    @State private var isExpanded = false
    @State private var editName: String = ""
    @State private var editPrompt: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("\(stepNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.brandPrimary)
                        .cornerRadius(12)

                    Text(step.name)
                        .font(.appSubheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isExpanded {
                                // Save edits
                                let updated = AutomationStep(
                                    name: editName.isEmpty ? step.name : editName,
                                    systemPrompt: editPrompt.isEmpty ? step.systemPrompt : editPrompt,
                                    maxTokens: step.maxTokens
                                )
                                onUpdate(updated)
                            } else {
                                editName = step.name
                                editPrompt = step.systemPrompt
                            }
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "checkmark.circle.fill" : "pencil.circle")
                            .font(.body)
                            .foregroundStyle(isExpanded ? Color.statusSuccess : Color.brandPrimary)
                    }

                    if canRemove {
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(.statusError)
                        }
                    }
                }
            }

            // Prompt preview (collapsed)
            if !isExpanded {
                Text(step.systemPrompt)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let maxTokens = step.maxTokens {
                    Text("Max tokens: \(maxTokens)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Edit form (expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Step name", text: $editName)
                        .textFieldStyle(.roundedBorder)
                        .font(.appBody)

                    Text("System Prompt")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $editPrompt)
                        .font(.appBody)
                        .frame(minHeight: 80)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.surfaceElevated, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview {
    AgentChainBuilderView(
        steps: .constant([
            AutomationStep(name: "Fetch Data", systemPrompt: "Retrieve the latest data from the source", maxTokens: 512),
            AutomationStep(name: "Analyze", systemPrompt: "Analyze the data and generate insights", maxTokens: 1024),
        ])
    )
    .padding()
}
