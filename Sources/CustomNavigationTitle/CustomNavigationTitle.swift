#if os(iOS)

import SwiftUI

struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = Anchor<CGRect>?
    static let defaultValue: Value = nil
    static func reduce(value: inout Value, nextValue: () -> Value) {
        guard let newValue = nextValue() else { return }
        value = newValue
    }
}

extension View {
    public func titleVisibilityAnchor() -> some View {
        self.anchorPreference(
            key: BoundsPreferenceKey.self,
            value: .bounds
        ) { anchor in
            anchor
        }
    }
}

private struct ScrollAwareTitleModifier<V: View>: ViewModifier {
    @State private var isShowNavigationTitle = false
    let title: () -> V

    func body(content: Content) -> some View {
        content
            .backgroundPreferenceValue(BoundsPreferenceKey.self) { anchor in
                GeometryReader { proxy in
                    if let anchor {
                        let scrollFrame = proxy.frame(in: .local).minY
                        let itemFrame = proxy[anchor]
                        let isVisible = itemFrame.maxY > scrollFrame
                        DispatchQueue.main.async{
                            if isVisible {
                                isShowNavigationTitle = false
                            } else if !isVisible {
                                isShowNavigationTitle = true
                            }
                        }
                    }
                    return Color.clear
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    title()
                        .bold()
                        .lineLimit(1)
                        .opacity(isShowNavigationTitle ? 1 : 0)
                        .animation(.easeIn(duration: 0.15), value: isShowNavigationTitle)
                }
            }
    }
}

extension View {
    public func scrollAwareTitle<V: View>(@ViewBuilder _ title: @escaping () -> V) -> some View {
        modifier(ScrollAwareTitleModifier(title: title))
    }
}

extension View {
    public func scrollAwareTitle<S: StringProtocol>(_ title: S) -> some View {
        scrollAwareTitle{
            Text(title)
        }
    }
    public func scrollAwareTitle(_ title: LocalizedStringKey) -> some View {
        scrollAwareTitle{
            Text(title)
        }
    }
}

#endif
