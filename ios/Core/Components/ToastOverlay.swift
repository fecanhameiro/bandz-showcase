import SwiftUI

struct ToastOverlay: ViewModifier {
    @SwiftUI.Environment(ToastCenter.self) private var center: ToastCenter?
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let center {
                    GeometryReader { geo in
                        VStack(spacing: SpacingSystem.Size.sm) {
                            ForEach(center.activeToasts) { toast in
                                BandzToastView(toast: toast)
                                    .transition(reduceMotion ? .opacity : .bandzToast)
                            }
                        }
                        .padding(.top, geo.safeAreaInsets.top + SpacingSystem.Size.sm)
                        .padding(.horizontal, SpacingSystem.Inset.card)
                        .frame(maxWidth: .infinity)
                        .zIndex(999)
                        .animation(
                            reduceMotion ? .easeOut(duration: 0.18)
                            : .spring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.2),
                            value: center.activeToasts
                        )
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

public extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlay())
    }
}

// MARK: - Custom Toast Transition
private extension AnyTransition {
    // Asymmetric, subtle springy transition for toast insert/remove
    static var bandzToast: AnyTransition {
        let insertion = AnyTransition.move(edge: .top)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.98, anchor: .top))

        let removal = AnyTransition.move(edge: .top)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.96, anchor: .top))

        return .asymmetric(insertion: insertion, removal: removal)
    }
}
