import SwiftUI

// MARK: - Generic Shimmer Modifier (works with any view/text style)
struct TextShimmerModifier: ViewModifier {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @State private var shimmerPhase: CGFloat = 0
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .leading) {
                GeometryReader { g in
                    let tw = g.size.width
                    let sweep = max(60, tw * 0.6)
                    let x = -sweep + (tw + sweep * 2) * shimmerPhase
                    let isDark = (colorScheme == .dark)
                    LinearGradient(
                        colors: isDark
                            ? [Color.white.opacity(0.0), Color.white.opacity(0.35), Color.white.opacity(0.0)]
                            : [Color.white.opacity(0.0), Color.white.opacity(0.65), Color.white.opacity(0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: sweep)
                    .offset(x: x)
                    .blendMode(isDark ? .plusLighter : .screen)
                    .animation(.linear(duration: 2.2).repeatForever(autoreverses: false), value: shimmerPhase)
                }
                .allowsHitTesting(false)
                .opacity(colorScheme == .dark ? 0.6 : 0.5)
            }
            .onAppear {
                guard !isAnimating else { return }
                isAnimating = true
                shimmerPhase = 0
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }
            .onDisappear {
                isAnimating = false
                shimmerPhase = 0
            }
    }
}

// MARK: - BandzShimmerText (single-line display text with shimmer)
public struct BandzShimmerText: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    public let text: String
    @State private var shimmerPhase: CGFloat = 0
    @State private var isAnimating: Bool = false

    public init(text: String) { self.text = text }

    public var body: some View {
        ZStack {
            Text(text)
                .displayXLargeFutura(alignment: .center)
                .bandzForegroundStyle(.primary)
                .tracking(1.2)
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.45 : 0.15),
                    radius: colorScheme == .dark ? 8 : 6,
                    x: 0,
                    y: colorScheme == .dark ? 3 : 2
                )
                .padding(.vertical, 8)
                .overlay(alignment: .leading) { textShimmerOverlay }
                .onAppear {
                    guard !isAnimating else { return }
                    isAnimating = true
                    shimmerPhase = 0
                    withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                        shimmerPhase = 1
                    }
                }
                .onDisappear {
                    isAnimating = false
                    shimmerPhase = 0
                }
        }
    }

    private var textShimmerOverlay: some View {
        GeometryReader { g in
            let tw = g.size.width
            let sweep = max(60, tw * 0.6)
            let x = -sweep + (tw + sweep * 2) * shimmerPhase
            let isDark = (colorScheme == .dark)
            let gradient = LinearGradient(
                colors: isDark
                    ? [Color.white.opacity(0.0), Color.black.opacity(0.50), Color.white.opacity(0.0)]
                    : [Color.white.opacity(0.0), Color.white.opacity(0.75), Color.white.opacity(0.0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            gradient
                .frame(width: sweep)
                .offset(x: x)
                .blendMode(isDark ? .multiply : .screen)
                .animation(.linear(duration: 1.8).repeatForever(autoreverses: false), value: shimmerPhase)
        }
        .mask(
            Text(text)
                .displayXLargeFutura(alignment: .center)
                .lineLimit(1)
        )
        .allowsHitTesting(false)
        .opacity(colorScheme == .dark ? 0.65 : 0.55)
    }
}

