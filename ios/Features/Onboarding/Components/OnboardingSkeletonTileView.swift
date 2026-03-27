//
//  OnboardingSkeletonTileView.swift
//  Bandz
//
//  Unified skeleton loading tile for onboarding grids (genres, places).
//

import SwiftUI

struct OnboardingSkeletonTileView: View {
    let variant: Variant
    let animationDelay: Double
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    enum Variant {
        /// Circle icon placeholder (used for genre/style tiles)
        case circle
        /// Rounded rectangle placeholder (used for place tiles)
        case rectangle
    }

    private let iconSize: CGFloat = 64
    private var iconHeight: CGFloat { variant == .circle ? iconSize : 56 }
    private let placeholderTitleWidth: CGFloat = 80
    private let placeholderSubtitleWidth: CGFloat = 60
    private var placeholderTitleHeight: CGFloat { variant == .circle ? Typography.FontSize.body : Typography.FontSize.small }
    private var placeholderSubtitleHeight: CGFloat { variant == .circle ? Typography.FontSize.xSmall : Typography.FontSize.micro }
    private let tileHeight: CGFloat = 140

    var body: some View {
        VStack(spacing: SpacingSystem.Size.sm) {
            iconPlaceholder
                .overlay { shimmerOverlay }

            RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.medium)
                .fill(ColorSystem.Text.secondary.opacity(0.1))
                .frame(height: placeholderTitleHeight)
                .frame(maxWidth: placeholderTitleWidth)

            RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.medium)
                .fill(ColorSystem.Text.secondary.opacity(0.1))
                .frame(height: placeholderSubtitleHeight)
                .frame(maxWidth: placeholderSubtitleWidth)
        }
        .padding(SpacingSystem.Size.md)
        .frame(maxWidth: .infinity)
        .frame(height: tileHeight)
        .background(
            RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
                .fill(ColorSystem.Text.secondary.opacity(0.08))
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(animationDelay)
            ) {
                isAnimating = true
            }
        }
    }

    @ViewBuilder
    private var iconPlaceholder: some View {
        switch variant {
        case .circle:
            Circle()
                .fill(ColorSystem.Text.secondary.opacity(0.1))
                .frame(width: iconSize, height: iconSize)
        case .rectangle:
            RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.medium)
                .fill(ColorSystem.Text.secondary.opacity(0.1))
                .frame(height: iconHeight)
        }
    }

    private var shimmerOverlay: some View {
        Group {
            switch variant {
            case .circle:
                Circle()
                    .fill(shimmerGradient)
                    .opacity(isAnimating ? 1 : 0)
            case .rectangle:
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.medium)
                    .fill(shimmerGradient)
                    .opacity(isAnimating ? 1 : 0)
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.clear,
                ColorSystem.Text.secondary.opacity(0.2),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
