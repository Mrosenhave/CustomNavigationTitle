#if os(iOS)

import SwiftUI

struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = Anchor<CGRect>?
    static let defaultValue: Value = nil
    static func reduce(value: inout Value, nextValue: () -> Value) {
      if let newValue = nextValue(), newValue != value {
              value = newValue
          }
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

public enum ScrollAwareTitleStyle: Equatable {
  case onOff
  case dynamicOpacity
  case dynamicOpacityWithOffset
}


private struct ScrollAwareTitleModifier<V: View>: ViewModifier {
    let title: () -> V
    let style: ScrollAwareTitleStyle
  
    @State private var navigationTitleVisibility: Double = 0.0

    func body(content: Content) -> some View {
        content
            .backgroundPreferenceValue(BoundsPreferenceKey.self) { anchor in
                GeometryReader { proxy in
                    if let anchor {
                        let scrollFrame = proxy.frame(in: .local).minY
                        let itemFrame = proxy[anchor]
                        let visibleRatio = min(1, max(0.0, (itemFrame.maxY - scrollFrame) / itemFrame.height))
                        let anchorIsVisible = itemFrame.maxY > scrollFrame
                        
                        let newValue: Double
                        if style == .onOff {
                          newValue = anchorIsVisible ? 0.0 : 1.0
                        } else {
                          newValue = 1.0 - visibleRatio
                        }
                      
                        if newValue != navigationTitleVisibility {
                          DispatchQueue.main.async {
                            navigationTitleVisibility = newValue
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
                        .opacity(navigationTitleVisibility)
                        .offset(y: (style == .dynamicOpacityWithOffset) ? (1.0 - navigationTitleVisibility) * 6 : 0)
                        .animation((style == .onOff) ? .easeIn(duration: 0.15) : nil, value: navigationTitleVisibility)
                }
            }
    }
}

extension View {
    public func scrollAwareTitle<V: View>(style: ScrollAwareTitleStyle, @ViewBuilder _ title: @escaping () -> V) -> some View {
        modifier(ScrollAwareTitleModifier(title: title, style: style))
    }
}

extension View {
    public func scrollAwareTitle<S: StringProtocol>(_ title: S, style: ScrollAwareTitleStyle = .onOff) -> some View {
        scrollAwareTitle(style: style){
            Text(title)
        }
    }
    public func scrollAwareTitle(_ title: LocalizedStringKey, style: ScrollAwareTitleStyle = .onOff) -> some View {
        scrollAwareTitle(style: style){
            Text(title)
        }
    }
}

#endif
