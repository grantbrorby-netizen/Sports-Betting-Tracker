import SwiftUI

struct TriggerConfigView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var selectedDays: Set<Int>

    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 20) {
            // Time picker
            timePickerSection

            // Day of week selector
            dayOfWeekSection

            // Quick presets
            presetButtons
        }
    }

    // MARK: - Time Picker

    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Time", systemImage: "clock")
                .sectionHeader()

            HStack(spacing: 0) {
                // Hour picker
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formattedHour(hour))
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Text(":")
                    .font(.appTitle)
                    .foregroundStyle(.primary)

                // Minute picker
                Picker("Minute", selection: $selectedMinute) {
                    ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // AM/PM indicator
                Text(selectedHour < 12 ? "AM" : "PM")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 40)
            }
            .frame(height: 120)
            .cardStyle()
        }
    }

    private func formattedHour(_ hour: Int) -> String {
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(displayHour)
    }

    // MARK: - Day of Week Selector

    private var dayOfWeekSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Days", systemImage: "calendar")
                .sectionHeader()

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    DayToggle(
                        label: dayLabels[index],
                        isSelected: selectedDays.contains(index)
                    ) {
                        toggleDay(index)
                    }
                }
            }
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            // Don't allow deselecting the last day
            if selectedDays.count > 1 {
                selectedDays.remove(day)
            }
        } else {
            selectedDays.insert(day)
        }
        Haptics.selection()
    }

    // MARK: - Preset Buttons

    private var presetButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quick Presets", systemImage: "wand.and.stars")
                .sectionHeader()

            HStack(spacing: 10) {
                presetButton("Every Day", days: Set(0..<7))
                presetButton("Weekdays", days: Set([1, 2, 3, 4, 5]))
                presetButton("Weekends", days: Set([0, 6]))
            }
        }
    }

    private func presetButton(_ title: String, days: Set<Int>) -> some View {
        let isActive = selectedDays == days

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDays = days
            }
            Haptics.light()
        } label: {
            Text(title)
                .font(.appCaption)
                .foregroundStyle(isActive ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isActive ? AnyShapeStyle(Color.brandGradient) : AnyShapeStyle(Color.surfaceElevated))
                .cornerRadius(20)
        }
    }
}

// MARK: - Day Toggle

private struct DayToggle: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color.brandPrimary : Color.surfaceElevated)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    TriggerConfigView(
        selectedHour: .constant(7),
        selectedMinute: .constant(0),
        selectedDays: .constant(Set([1, 2, 3, 4, 5]))
    )
    .padding()
}
