import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.surfaceCard)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    func sectionHeader() -> some View {
        self
            .font(.appHeadline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
