import Foundation

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    let totalPages = 3

    var isLastPage: Bool {
        currentPage >= totalPages - 1
    }

    func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }
}
