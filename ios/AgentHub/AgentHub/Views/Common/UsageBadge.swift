import SwiftUI

struct UsageBadge: View {
    let isByok: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isByok ? "key.fill" : "cpu")
                .font(.caption2)
            Text(isByok ? "Your Key" : "AgentHub")
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(isByok ? .orange : .brandPrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            (isByok ? Color.orange : Color.brandPrimary).opacity(0.1)
        )
        .cornerRadius(6)
    }
}
