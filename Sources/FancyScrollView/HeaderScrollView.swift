import SwiftUI

private let navigationBarHeight: CGFloat = 44

private struct LargeTitleWeightPreferenceKey: PreferenceKey {
    static var defaultValue: Double = 1
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}

struct HeaderScrollView: View {
    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme

    let title: String
    let titleColor: Color
    let font: Font
    let headerHeight: CGFloat
    let scrollUpBehavior: ScrollUpHeaderBehavior
    let scrollDownBehavior: ScrollDownHeaderBehavior
    let header: AnyView
    let content: AnyView

    @State private var currentLargeTitleWeight: Double = 1

    var body: some View {
        GeometryReader { globalGeometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    GeometryReader { geometry -> AnyView in
                        let geometry = self.geometry(from: geometry, safeArea: globalGeometry.safeAreaInsets)
                        AnyView(
                            self.header
                                .frame(width: geometry.width,
                                       height: geometry.headerHeight)
                                .clipped()
                                .opacity(sqrt(geometry.largeTitleWeight))
                                .offset(y: geometry.headerOffset)
                                .overlay(
                                    GeometryReader { overlayGeo in
                                        let currentHeight = overlayGeo.size.height
                                        let halfHeight = currentHeight / 2.0
                                        
                                        VStack {
                                            Spacer()
                                            LinearGradient(
                                                colors: [.black.opacity(0.5), .clear],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                            .frame(height: halfHeight)
                                        }
                                    }
                                        .opacity(sqrt(geometry.largeTitleWeight))
                                )
                                .transformPreference(LargeTitleWeightPreferenceKey.self) { _ in
                                }
                                .background(
                                    Color.clear.preference(key: LargeTitleWeightPreferenceKey.self, value: geometry.largeTitleWeight)
                                )
                        )
                    }
                    .frame(width: globalGeometry.size.width, height: self.headerHeight)
                    

                    GeometryReader { geometry -> AnyView in
                        let geometry = self.geometry(from: geometry, safeArea: globalGeometry.safeAreaInsets)
                        AnyView(
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .edgesIgnoringSafeArea(.all)

                                VStack {
                                    Spacer()
                                    
                                    HeaderScrollViewTitle(
                                        title: self.title,
                                        titleColor: self.titleColor,
                                        font: self.font,
                                        height: navigationBarHeight,
                                        largeTitle: geometry.largeTitleWeight
                                    )
                                    .layoutPriority(1000)
                                }
                                .padding(.top, globalGeometry.safeAreaInsets.top)
                                .frame(width: geometry.width,
                                       height: max(geometry.elementsHeight, navigationBarHeight))
                                .offset(y: geometry.elementsOffset)
                            }
                            .background(
                                Color.clear.preference(key: LargeTitleWeightPreferenceKey.self, value: geometry.largeTitleWeight)
                            )
                        )
                    }
                    .frame(width: globalGeometry.size.width, height: self.headerHeight)
                    .zIndex(1000)
                    .offset(y: -self.headerHeight)

                    self.content
                        .background(Color.background(colorScheme: self.colorScheme))
                        .offset(y: -self.headerHeight)
                        .padding(.bottom, -self.headerHeight)
                }
            }
            .onPreferenceChange(LargeTitleWeightPreferenceKey.self) { value in
                currentLargeTitleWeight = min(max(value, 0), 1)
            }
            .navigationTitle(currentLargeTitleWeight == 0 ? title : "")
            .modifier(InlineTitleDisplayMode())
            .edgesIgnoringSafeArea(.top)
        }
    }
}

private struct InlineTitleDisplayMode: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.toolbarTitleDisplayMode(.inline)
        } else {
            content.navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension HeaderScrollView {

    private struct HeaderScrollViewGeometry {
        let width: CGFloat
        let headerHeight: CGFloat
        let elementsHeight: CGFloat
        let headerOffset: CGFloat
        let blurOffset: CGFloat
        let elementsOffset: CGFloat
        let largeTitleWeight: Double
    }

    private func geometry(from geometry: GeometryProxy, safeArea: EdgeInsets) -> HeaderScrollViewGeometry {
        let minY = geometry.frame(in: .global).minY
        let hasScrolledUp = minY > 0
        let hasScrolledToMinHeight = -minY >= headerHeight - safeArea.top

        let headerHeight = hasScrolledUp && self.scrollUpBehavior == .parallax ?
            geometry.size.height + minY : geometry.size.height

        let elementsHeight = hasScrolledUp && self.scrollUpBehavior == .sticky ?
            geometry.size.height : geometry.size.height + minY

        let headerOffset: CGFloat
        let blurOffset: CGFloat
        let elementsOffset: CGFloat
        let largeTitleWeight: Double

        if hasScrolledUp {
            headerOffset = -minY
            blurOffset = -minY
            elementsOffset = -minY
            largeTitleWeight = 1
        } else if hasScrolledToMinHeight {
            headerOffset = -minY - self.headerHeight + navigationBarHeight + safeArea.top
            blurOffset = -minY - self.headerHeight + navigationBarHeight + safeArea.top
            elementsOffset = headerOffset / 2 - minY / 2
            largeTitleWeight = 0
        } else {
            headerOffset = self.scrollDownBehavior == .sticky ? -minY : 0
            blurOffset = 0
            elementsOffset = -minY / 2
            let difference = self.headerHeight - navigationBarHeight - safeArea.top + minY
            largeTitleWeight = difference <= navigationBarHeight + 1 ? Double(difference / (navigationBarHeight + 1)) : 1
        }

        return HeaderScrollViewGeometry(width: geometry.size.width,
                                        headerHeight: headerHeight,
                                        elementsHeight: elementsHeight,
                                        headerOffset: headerOffset,
                                        blurOffset: blurOffset,
                                        elementsOffset: elementsOffset,
                                        largeTitleWeight: largeTitleWeight)
    }
}

extension Color {
    static func background(colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return .black
        case .light:
            fallthrough
        @unknown default:
            return .white
        }
    }
}
