import SwiftUI

struct IconBadgeView: View {
    let iconName: String
    var size: CGFloat = 44
    var backgroundColor: Color = .brandPrimary.opacity(0.1)
    var iconColor: Color = .brandPrimary

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size * 0.45))
            .foregroundStyle(iconColor)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .cornerRadius(size * 0.25)
    }
}
