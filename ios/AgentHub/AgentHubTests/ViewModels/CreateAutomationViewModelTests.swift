import XCTest
@testable import AgentHub

@MainActor
final class CreateAutomationViewModelTests: XCTestCase {

    // MARK: - Cron Generation

    func testCronFromDailySelection() {
        let vm = CreateAutomationViewModel()
        vm.selectedHour = 7
        vm.selectedMinute = 0
        vm.selectedDays = [0, 1, 2, 3, 4, 5, 6] // every day

        XCTAssertEqual(vm.cronExpression, "0 7 * * *")
    }

    func testCronFromWeekdaySelection() {
        let vm = CreateAutomationViewModel()
        vm.selectedHour = 9
        vm.selectedMinute = 30
        vm.selectedDays = [1, 2, 3, 4, 5] // Mon-Fri

        XCTAssertEqual(vm.cronExpression, "30 9 * * 1,2,3,4,5")
    }

    func testCronFromSingleDay() {
        let vm = CreateAutomationViewModel()
        vm.selectedHour = 17
        vm.selectedMinute = 0
        vm.selectedDays = [5] // Friday only

        XCTAssertEqual(vm.cronExpression, "0 17 * * 5")
    }

    func testCronFromWeekend() {
        let vm = CreateAutomationViewModel()
        vm.selectedHour = 10
        vm.selectedMinute = 15
        vm.selectedDays = [0, 6] // Sat, Sun

        XCTAssertEqual(vm.cronExpression, "15 10 * * 0,6")
    }

    // MARK: - Schedule Preview

    func testSchedulePreviewDaily() {
        let vm = CreateAutomationViewModel()
        vm.selectedHour = 7
        vm.selectedMinute = 0
        vm.selectedDays = [0, 1, 2, 3, 4, 5, 6]

        XCTAssertTrue(vm.schedulePreview.contains("Every day"))
        XCTAssertTrue(vm.schedulePreview.contains("7:00"))
    }

    func testSchedulePreviewWeekdays() {
        let vm = CreateAutomationViewModel()
        vm.selectedHour = 9
        vm.selectedMinute = 0
        vm.selectedDays = [1, 2, 3, 4, 5]

        XCTAssertTrue(vm.schedulePreview.contains("Weekdays"))
    }

    // MARK: - Validation

    func testCanSaveRequiresTemplate() {
        let vm = CreateAutomationViewModel()
        vm.name = "Test Automation"
        vm.selectedDays = [1, 2, 3]

        XCTAssertFalse(vm.canSave, "Should not save without a template")
    }

    func testCanSaveRequiresName() {
        let vm = CreateAutomationViewModel()
        vm.name = ""
        vm.selectedDays = [1, 2, 3]

        XCTAssertFalse(vm.canSave, "Should not save without a name")
    }

    func testCanSaveRequiresDays() {
        let vm = CreateAutomationViewModel()
        vm.name = "Test"
        vm.selectedDays = []

        XCTAssertFalse(vm.canSave, "Should not save without selected days")
    }

    // MARK: - Initial State

    func testInitialState() {
        let vm = CreateAutomationViewModel()

        XCTAssertNil(vm.selectedTemplate)
        XCTAssertTrue(vm.name.isEmpty)
        XCTAssertEqual(vm.selectedHour, 7)
        XCTAssertEqual(vm.selectedMinute, 0)
        XCTAssertFalse(vm.isSaving)
        XCTAssertNil(vm.errorMessage)
    }
}
