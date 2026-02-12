import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            illustrationIcon

            VStack(spacing: 8) {
                Text("No agents yet")
                    .font(.appTitle)
                    .foregroundStyle(.primary)

                Text("Browse the store to discover and install agents that help you get things done.")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            browseStoreButton

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Illustration

    private var illustrationIcon: some View {
        ZStack {
            Circle()
                .fill(Color.brandPrimary.opacity(0.08))
                .frame(width: 120, height: 120)

            Circle()
                .fill(Color.brandPrimary.opacity(0.12))
                .frame(width: 88, height: 88)

            Image(systemName: "square.grid.2x2")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Color.brandPrimary)
        }
    }

    // MARK: - Browse Store Button

    private var browseStoreButton: some View {
        NavigationLink {
            AgentStoreDestination()
        } label: {
            Text("Browse Store")
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 40)
        .padding(.top, 8)
    }
}

// MARK: - AgentStore Navigation Placeholder

/// Placeholder destination for navigating to the Agent Store tab.
/// Replace with actual AgentStoreView once implemented.
private struct AgentStoreDestination: View {
    var body: some View {
        Text("Agent Store")
            .navigationTitle("Store")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EmptyStateView()
    }
}
