import SwiftUI

struct AgentCardView: View {
    let agent: InstalledAgent

    var body: some View {
        HStack(spacing: 14) {
            IconBadgeView(
                iconName: agent.template?.iconName ?? "cpu",
                size: 44
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(agent.displayName)
                    .font(.appSubheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let lastUsed = agent.lastUsedAt {
                    Text(lastUsed.relativeDescription)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if agent.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(Color.brandPrimary)
                    .rotationEffect(.degrees(-45))
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.surfaceCard)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }
}

// MARK: - Date Relative Description

private extension Date {
    var relativeDescription: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        switch interval {
        case ..<60:
            return "Just now"
        case ..<3600:
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        case ..<86400:
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        case ..<604_800:
            let days = Int(interval / 86400)
            return "\(days)d ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: self)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 10) {
        AgentCardView(
            agent: InstalledAgent(
                id: UUID(),
                userId: UUID(),
                templateId: UUID(),
                customName: "My Writing Assistant",
                isPinned: true,
                sortOrder: 0,
                lastUsedAt: Date().addingTimeInterval(-7200),
                installedAt: Date(),
                template: nil
            )
        )

        AgentCardView(
            agent: InstalledAgent(
                id: UUID(),
                userId: UUID(),
                templateId: UUID(),
                customName: "Finance Analyzer",
                isPinned: false,
                sortOrder: 1,
                lastUsedAt: Date().addingTimeInterval(-86400),
                installedAt: Date(),
                template: nil
            )
        )
    }
    .padding()
    .background(Color.surfaceGrouped)
}
