import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("cpu.fill", "AI Helpers That Work for You",
         "Browse a marketplace of smart agents. Draft emails, explain bills, prep for appointments — just fill in a form and go."),
        ("clock.badge.checkmark.fill", "Set It and Forget It",
         "Create automations that run in the background. Get a daily plan every morning. Weekly spending check-ins. All delivered via push notification."),
        ("sparkles", "Start Your Free Trial",
         "Try Pro features free for 7 days. No credit card required. Cancel anytime."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: pages[index].icon)
                            .font(.system(size: 70))
                            .foregroundStyle(Color.brandGradient)
                            .padding(.bottom, 8)

                        Text(pages[index].title)
                            .font(.appLargeTitle)
                            .multilineTextAlignment(.center)

                        Text(pages[index].subtitle)
                            .font(.appBody)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // Bottom button
            VStack(spacing: 12) {
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                }
                .buttonStyle(PrimaryButtonStyle())

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        hasCompletedOnboarding = true
                    }
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
