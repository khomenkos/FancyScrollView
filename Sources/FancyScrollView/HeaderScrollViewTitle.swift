import SwiftUI

struct HeaderScrollViewTitle: View {
    let title: String
    let titleColor: Color
    let font: Font
    let height: CGFloat
    let largeTitle: Double

    var body: some View {
        let largeTitleOpacity = (max(largeTitle, 0.5) - 0.5) * 2
        return ZStack {
            HStack {
                Text(title)
                    .font(font)
                    .foregroundColor(titleColor)
                    .padding(.horizontal, 16)
                Spacer()
            }
            .padding(.bottom, 8)
            .opacity(sqrt(largeTitleOpacity))
            .minimumScaleFactor(0.5)
        }
        .frame(height: height)
    }
}
