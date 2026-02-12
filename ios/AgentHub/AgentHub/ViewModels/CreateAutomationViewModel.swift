import Foundation

@MainActor
final class CreateAutomationViewModel: ObservableObject {
    // MARK: - Step Navigation

    enum Step: Int, CaseIterable {
        case selectTemplate = 0
        case configureSchedule = 1
        case setInputs = 2
        case review = 3

        var title: String {
            switch self {
            case .selectTemplate: return "Choose Template"
            case .configureSchedule: return "Set Schedule"
            case .setInputs: return "Configure Inputs"
            case .review: return "Review"
            }
        }
    }

    @Published var currentStep: Step = .selectTemplate

    // MARK: - Template Selection

    @Published var availableTemplates: [AgentTemplate] = []
    @Published var selectedTemplate: AgentTemplate?

    // MARK: - Configuration

    @Published var name = ""
    @Published var cronExpression = ""
    @Published var timezone: String = TimeZone.current.identifier
    @Published var inputValues: [String: String] = [:]
    @Published var modelTier: String = ModelTier.fast.rawValue
    @Published var actionType: String = "push_notification"
    @Published var pushTitle: String = ""

    // MARK: - Schedule Picker State

    @Published var selectedHour: Int = 7
    @Published var selectedMinute: Int = 0
    @Published var selectedDays: Set<Int> = Set([1, 2, 3, 4, 5]) // Mon-Fri

    // MARK: - Steps (Agent Chain)

    @Published var steps: [AutomationStep] = []

    // MARK: - State

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var cronFromSelection: String {
        let dayString: String
        if selectedDays.count == 7 || selectedDays.isEmpty {
            dayString = "*"
        } else {
            dayString = selectedDays.sorted().map(String.init).joined(separator: ",")
        }
        return "\(selectedMinute) \(selectedHour) * * \(dayString)"
    }

    var schedulePreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = selectedHour
        components.minute = selectedMinute

        let timeString: String
        if let date = Calendar.current.date(from: components) {
            timeString = formatter.string(from: date)
        } else {
            timeString = "\(selectedHour):\(String(format: "%02d", selectedMinute))"
        }

        if selectedDays.count == 7 || selectedDays.isEmpty {
            return "Every day at \(timeString)"
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let weekdays = Set([1, 2, 3, 4, 5])
        let weekends = Set([0, 6])

        if selectedDays == weekdays {
            return "Every weekday at \(timeString)"
        }
        if selectedDays == weekends {
            return "Every weekend at \(timeString)"
        }

        let labels = selectedDays.sorted()
            .filter { $0 >= 0 && $0 < dayNames.count }
            .map { dayNames[$0] }

        if labels.count == 1 {
            return "Every \(labels[0]) at \(timeString)"
        }

        return "\(labels.joined(separator: ", ")) at \(timeString)"
    }

    var canProceedToNext: Bool {
        switch currentStep {
        case .selectTemplate:
            return selectedTemplate != nil
        case .configureSchedule:
            return !selectedDays.isEmpty
        case .setInputs:
            return true
        case .review:
            return !name.isEmpty
        }
    }

    var isLastStep: Bool {
        currentStep == .review
    }

    var isFirstStep: Bool {
        currentStep == .selectTemplate
    }

    // MARK: - Load Templates

    func loadTemplates() async {
        isLoading = true
        do {
            availableTemplates = try await AgentRegistryService.shared.fetchTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Template Selection

    func selectTemplate(_ template: AgentTemplate) {
        selectedTemplate = template
        name = template.name

        // Pre-fill steps from template
        steps = [
            AutomationStep(
                name: template.name,
                systemPrompt: template.systemPrompt,
                maxTokens: template.maxTokens
            )
        ]

        // Pre-fill input values from template schema defaults
        inputValues = [:]
        for field in template.inputSchema {
            if let defaultValue = field.defaultValue {
                inputValues[field.id] = defaultValue.stringValue
            }
        }

        modelTier = template.defaultModelTier
        Haptics.light()
    }

    // MARK: - Navigation

    func goToNextStep() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
        Haptics.light()
    }

    func goToPreviousStep() {
        guard let prevStep = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevStep
        Haptics.light()
    }

    // MARK: - Save

    func save() async -> Automation? {
        guard let template = selectedTemplate else { return nil }

        isSaving = true
        errorMessage = nil

        // Update cron from selection
        cronExpression = cronFromSelection

        do {
            let automation = try await AutomationService.shared.createAutomation(
                name: name,
                templateId: template.templateId,
                cronExpression: cronExpression,
                timezone: timezone,
                steps: steps,
                inputValues: inputValues,
                actionType: actionType,
                pushTitle: pushTitle.isEmpty ? name : pushTitle,
                modelTier: modelTier
            )
            Haptics.success()
            isSaving = false
            return automation
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
            isSaving = false
            return nil
        }
    }
}
