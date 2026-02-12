import XCTest
@testable import AgentHub

@MainActor
final class AgentUsageViewModelTests: XCTestCase {

    // MARK: - Initialization

    func testInitSetsDefaultModelTier() {
        let template = makeTemplate(defaultModelTier: "smart")
        let vm = AgentUsageViewModel(template: template)

        XCTAssertEqual(vm.selectedModelTier, .smart)
    }

    func testInitFallsBackToFastForUnknownTier() {
        let template = makeTemplate(defaultModelTier: "unknown")
        let vm = AgentUsageViewModel(template: template)

        XCTAssertEqual(vm.selectedModelTier, .fast)
    }

    func testInitPreFillsDefaultValues() {
        let template = makeTemplate(inputs: [
            AgentInputField(id: "tone", type: .select, label: "Tone", placeholder: nil, required: false, options: ["formal", "casual"], defaultValue: .string("formal")),
            AgentInputField(id: "length", type: .number, label: "Length", placeholder: nil, required: false, options: nil, defaultValue: .number(500)),
        ])
        let vm = AgentUsageViewModel(template: template)

        XCTAssertEqual(vm.formValues["tone"], "formal")
        XCTAssertEqual(vm.formValues["length"], "500.0")
    }

    // MARK: - Required Fields Validation

    func testRequiredFieldsMissingWhenEmpty() {
        let template = makeTemplate(inputs: [
            AgentInputField(id: "topic", type: .text, label: "Topic", placeholder: nil, required: true, options: nil, defaultValue: nil),
            AgentInputField(id: "tone", type: .select, label: "Tone", placeholder: nil, required: false, options: nil, defaultValue: nil),
        ])
        let vm = AgentUsageViewModel(template: template)

        XCTAssertEqual(vm.requiredFieldsMissing, ["Topic"])
    }

    func testRequiredFieldsSatisfiedWhenFilled() {
        let template = makeTemplate(inputs: [
            AgentInputField(id: "topic", type: .text, label: "Topic", placeholder: nil, required: true, options: nil, defaultValue: nil),
        ])
        let vm = AgentUsageViewModel(template: template)
        vm.formValues["topic"] = "Test email"

        XCTAssertTrue(vm.requiredFieldsMissing.isEmpty)
    }

    func testMultipleRequiredFieldsMissing() {
        let template = makeTemplate(inputs: [
            AgentInputField(id: "a", type: .text, label: "Field A", placeholder: nil, required: true, options: nil, defaultValue: nil),
            AgentInputField(id: "b", type: .text, label: "Field B", placeholder: nil, required: true, options: nil, defaultValue: nil),
            AgentInputField(id: "c", type: .text, label: "Field C", placeholder: nil, required: false, options: nil, defaultValue: nil),
        ])
        let vm = AgentUsageViewModel(template: template)

        XCTAssertEqual(vm.requiredFieldsMissing.count, 2)
        XCTAssertTrue(vm.requiredFieldsMissing.contains("Field A"))
        XCTAssertTrue(vm.requiredFieldsMissing.contains("Field B"))
    }

    // MARK: - canExecute

    func testCanExecuteWhenAllRequiredFilled() {
        let template = makeTemplate(inputs: [
            AgentInputField(id: "topic", type: .text, label: "Topic", placeholder: nil, required: true, options: nil, defaultValue: nil),
        ])
        let vm = AgentUsageViewModel(template: template)
        vm.formValues["topic"] = "Hello"

        XCTAssertTrue(vm.canExecute)
    }

    func testCannotExecuteWhenRequiredMissing() {
        let template = makeTemplate(inputs: [
            AgentInputField(id: "topic", type: .text, label: "Topic", placeholder: nil, required: true, options: nil, defaultValue: nil),
        ])
        let vm = AgentUsageViewModel(template: template)

        XCTAssertFalse(vm.canExecute)
    }

    func testCannotExecuteWhileExecuting() {
        let template = makeTemplate(inputs: [])
        let vm = AgentUsageViewModel(template: template)
        vm.isExecuting = true

        XCTAssertFalse(vm.canExecute)
    }

    func testCanExecuteWithNoInputs() {
        let template = makeTemplate(inputs: [])
        let vm = AgentUsageViewModel(template: template)

        XCTAssertTrue(vm.canExecute, "Template with no required inputs should be executable")
    }

    // MARK: - clearResult

    func testClearResult() {
        let template = makeTemplate(inputs: [])
        let vm = AgentUsageViewModel(template: template)
        vm.errorMessage = "Some error"

        vm.clearResult()

        XCTAssertNil(vm.result)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Initial State

    func testInitialState() {
        let template = makeTemplate(inputs: [])
        let vm = AgentUsageViewModel(template: template)

        XCTAssertFalse(vm.isExecuting)
        XCTAssertNil(vm.result)
        XCTAssertNil(vm.errorMessage)
        XCTAssertTrue(vm.executionHistory.isEmpty)
    }

    // MARK: - Helpers

    private func makeTemplate(
        defaultModelTier: String = "fast",
        inputs: [AgentInputField] = []
    ) -> AgentTemplate {
        AgentTemplate(
            id: UUID(),
            templateId: "test-template",
            name: "Test Template",
            description: "A test template",
            category: "writing",
            iconName: "doc",
            systemPrompt: "You are a test agent.",
            inputSchema: inputs,
            outputFormat: "text",
            defaultModelTier: defaultModelTier,
            requiresVision: false,
            maxTokens: 1024,
            temperature: 0.7,
            isFeatured: false,
            isPublic: true,
            version: "1.0.0",
            author: "Test",
            createdAt: Date(),
            isInstalled: nil
        )
    }
}
