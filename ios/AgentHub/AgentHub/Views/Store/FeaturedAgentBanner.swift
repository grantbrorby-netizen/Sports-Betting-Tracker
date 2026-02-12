import SwiftUI

struct FeaturedAgentBanner: View {
    let templates: [AgentTemplate]
    var onInstall: ((AgentTemplate) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(templates) { template in
                    NavigationLink(value: template) {
                        FeaturedAgentCard(
                            template: template,
                            onInstall: onInstall
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Featured Agent Card

private struct FeaturedAgentCard: View {
    let template: AgentTemplate
    var onInstall: ((AgentTemplate) -> Void)?

    @State private var isInstalling = false

    private var gradientColors: [Color] {
        categoryGradient(for: template.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                IconBadgeView(
                    iconName: template.iconName,
                    size: 48,
                    backgroundColor: .white.opacity(0.2),
                    iconColor: .white
                )

                Spacer()

                installButton
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.appHeadline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(template.description)
                    .font(.appCaption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                if let tier = ModelTier(rawValue: template.defaultModelTier) {
                    Image(systemName: tier.iconName)
                        .font(.caption2)
                    Text(tier.displayName)
                        .font(.caption2.weight(.medium))
                }
            }
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(16)
        .frame(width: 260, height: 180)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: gradientColors[0].opacity(0.3), radius: 8, y: 4)
    }

    private var installButton: some View {
        Group {
            if template.isInstalled == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            } else {
                Button {
                    guard !isInstalling else { return }
                    isInstalling = true
                    Haptics.light()
                    onInstall?(template)

                    // Optimistic UI: reset after delay if callback doesn't update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        isInstalling = false
                    }
                } label: {
                    Text("Get")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(gradientColors[0])
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(.white)
                        .cornerRadius(14)
                }
                .disabled(isInstalling)
                .opacity(isInstalling ? 0.6 : 1.0)
            }
        }
    }

    private func categoryGradient(for category: String) -> [Color] {
        switch category {
        case "writing":
            return [Color(red: 0.25, green: 0.47, blue: 1.0), Color(red: 0.15, green: 0.35, blue: 0.85)]
        case "finance":
            return [Color(red: 0.13, green: 0.73, blue: 0.45), Color(red: 0.08, green: 0.55, blue: 0.35)]
        case "productivity":
            return [Color(red: 0.56, green: 0.27, blue: 1.0), Color(red: 0.40, green: 0.15, blue: 0.85)]
        case "health":
            return [Color(red: 1.0, green: 0.35, blue: 0.42), Color(red: 0.85, green: 0.20, blue: 0.30)]
        case "cooking":
            return [Color(red: 1.0, green: 0.6, blue: 0.0), Color(red: 0.90, green: 0.45, blue: 0.0)]
        case "legal":
            return [Color(red: 0.35, green: 0.35, blue: 0.45), Color(red: 0.25, green: 0.25, blue: 0.35)]
        default:
            return [Color.brandGradientStart, Color.brandGradientEnd]
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeaturedAgentBanner(
            templates: [
                AgentTemplate(
                    id: UUID(),
                    templateId: "preview-1",
                    name: "Email Composer",
                    description: "Draft professional emails effortlessly with AI-powered writing.",
                    category: "writing",
                    iconName: "envelope.fill",
                    systemPrompt: "",
                    inputSchema: [],
                    outputFormat: "text",
                    defaultModelTier: "fast",
                    requiresVision: false,
                    maxTokens: 2048,
                    temperature: 0.7,
                    isFeatured: true,
                    isPublic: true,
                    version: "1.0",
                    author: "AgentHub",
                    createdAt: Date(),
                    isInstalled: false
                ),
                AgentTemplate(
                    id: UUID(),
                    templateId: "preview-2",
                    name: "Budget Analyzer",
                    description: "Analyze your spending and get personalized financial insights.",
                    category: "finance",
                    iconName: "chart.pie.fill",
                    systemPrompt: "",
                    inputSchema: [],
                    outputFormat: "text",
                    defaultModelTier: "smart",
                    requiresVision: false,
                    maxTokens: 4096,
                    temperature: 0.5,
                    isFeatured: true,
                    isPublic: true,
                    version: "1.0",
                    author: "AgentHub",
                    createdAt: Date(),
                    isInstalled: true
                ),
            ]
        )
    }
}
