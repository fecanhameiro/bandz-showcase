//
//  BandzGlassButton.swift
//  Bandz
//
//  Consolidated glass button styles - parametrized for flexibility
//

import SwiftUI

// MARK: - Glass Button Configuration

/// Opacity intensity for glass buttons
enum GlassOpacity: CaseIterable {
    case ultraLight
    case subtle
    case medium
    case strong
    case ultraStrong

    // MARK: - Glass Style Properties

    var fillOpacity: Double {
        switch self {
        case .ultraLight: return 0.05
        case .subtle: return 0.08
        case .medium: return 0.15
        case .strong: return 0.25
        case .ultraStrong: return 0.40
        }
    }

    var overlayOpacity: Double {
        switch self {
        case .ultraLight: return 0.03
        case .subtle: return 0.04
        case .medium: return 0.10
        case .strong: return 0.18
        case .ultraStrong: return 0.35
        }
    }

    var borderTopOpacity: Double {
        switch self {
        case .ultraLight: return 0.25
        case .subtle: return 0.30
        case .medium: return 0.40
        case .strong: return 0.60
        case .ultraStrong: return 0.80
        }
    }

    var borderBottomOpacity: Double {
        switch self {
        case .ultraLight: return 0.05
        case .subtle: return 0.08
        case .medium: return 0.10
        case .strong: return 0.20
        case .ultraStrong: return 0.30
        }
    }

    var borderWidth: Double {
        switch self {
        case .ultraLight: return 0.8
        case .subtle: return 0.9
        case .medium: return 1.0
        case .strong: return 1.5
        case .ultraStrong: return 2.0
        }
    }

    var blurRadius: Double {
        switch self {
        case .ultraLight: return 0.3
        case .subtle: return 0.4
        case .medium: return 0.5
        case .strong: return 0.8
        case .ultraStrong: return 1.0
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .ultraLight: return 0.05
        case .subtle: return 0.08
        case .medium: return 0.12
        case .strong: return 0.15
        case .ultraStrong: return 0.25
        }
    }

    var shadowRadius: Double {
        switch self {
        case .ultraLight: return 8
        case .subtle: return 9
        case .medium: return 11
        case .strong: return 12
        case .ultraStrong: return 15
        }
    }

    var shadowY: Double {
        switch self {
        case .ultraLight: return 4
        case .subtle: return 4
        case .medium: return 5
        case .strong: return 6
        case .ultraStrong: return 8
        }
    }

    // MARK: - Backdrop Style Properties

    var backdropMaterialOpacity: Double {
        switch self {
        case .ultraLight: return 0.10
        case .subtle: return 0.15
        case .medium: return 0.30
        case .strong: return 0.50
        case .ultraStrong: return 0.80
        }
    }

    var backdropBlurRadius: Double {
        switch self {
        case .ultraLight: return 6
        case .subtle: return 7
        case .medium: return 8
        case .strong: return 10
        case .ultraStrong: return 12
        }
    }

    var backdropShadowRadius: Double {
        switch self {
        case .ultraLight: return 12
        case .subtle: return 13
        case .medium: return 15
        case .strong: return 18
        case .ultraStrong: return 25
        }
    }

    var backdropShadowY: Double {
        switch self {
        case .ultraLight: return 6
        case .subtle: return 7
        case .medium: return 8
        case .strong: return 10
        case .ultraStrong: return 12
        }
    }
}

/// Variant type for glass buttons
enum GlassVariant {
    case glass
    case backdrop
    case dark         // Special dark variant with adaptive colors
    case darkOverlay  // Dark variant with boosted fill for overlay contexts
}

// MARK: - Unified Glass Button Style

/// Single parametrized ButtonStyle that replaces all 11 individual styles
struct UnifiedGlassButtonStyle: ButtonStyle {
    let opacity: GlassOpacity
    let variant: GlassVariant

    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    init(opacity: GlassOpacity = .medium, variant: GlassVariant = .glass) {
        self.opacity = opacity
        self.variant = variant
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : ColorSystem.Brand.primary
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(Typography.TextStyle.buttonLarge, color: textColor, alignment: .center)
            .frame(maxWidth: .infinity)
            .frame(height: SpacingSystem.Height.largeButton)
            .background(backgroundView)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .glass:
            glassBackground
        case .backdrop:
            backdropBackground
        case .dark, .darkOverlay:
            darkGlassBackground
        }
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
            .fill(.clear)
            .background(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
                    .fill(.white.opacity(opacity.fillOpacity))
                    .blur(radius: opacity.blurRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
                            .fill(.white.opacity(opacity.overlayOpacity))
                    )
            )
            .overlay(glassBorder)
            .shadow(
                color: .black.opacity(opacity.shadowOpacity),
                radius: opacity.shadowRadius,
                x: 0,
                y: opacity.shadowY
            )
    }

    // MARK: - Backdrop Background

    private var backdropBackground: some View {
        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
            .fill(.regularMaterial.opacity(opacity.backdropMaterialOpacity))
            .background(
                Rectangle()
                    .fill(.clear)
                    .background(.regularMaterial.opacity(opacity.backdropMaterialOpacity * 0.4))
                    .blur(radius: opacity.backdropBlurRadius)
                    .clipShape(RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge))
            )
            .overlay(glassBorder)
            .shadow(
                color: .black.opacity(opacity.shadowOpacity + 0.05),
                radius: opacity.backdropShadowRadius,
                y: opacity.backdropShadowY
            )
    }

    // MARK: - Dark Glass Background

    /// Light-mode fill boost when used with overlay containers (darkOverlay variant)
    private var overlayBoostOpacity: Double {
        (variant == .darkOverlay && colorScheme == .light) ? 0.12 : 0.0
    }

    private var darkGlassBackground: some View {
        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
            .fill(.clear)
            .background(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
                    .fill(ColorSystem.System.buttonGlassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
                            .fill(ColorSystem.Brand.primary.opacity(overlayBoostOpacity))
                    )
                    .blur(radius: 0.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
                            .fill(.white.opacity(0.1))
                            .blur(radius: 0.8)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
                    .stroke(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [.white.opacity(0.45), .white.opacity(0.15)]
                                : [ColorSystem.Brand.primary.opacity(0.35), ColorSystem.Brand.primary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: colorScheme == .dark ? 1.0 : 1.8
                    )
            )
            .shadow(
                color: ColorSystem.System.buttonGlassShadow,
                radius: colorScheme == .dark ? 4.5 : 10,
                x: 0,
                y: colorScheme == .dark ? 0 : 5
            )
    }

    // MARK: - Glass Border

    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(opacity.borderTopOpacity),
                        .white.opacity(opacity.borderBottomOpacity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: opacity.borderWidth
            )
    }
}

// MARK: - BandzGlassButton Component

struct BandzGlassButton: View {
    let title: String
    let isLoading: Bool
    let style: GlassStyle
    let action: () -> Void

    /// Consolidated glass style enum - maps to UnifiedGlassButtonStyle
    enum GlassStyle {
        // Standard glass variants
        case standard           // medium glass
        case backdrop           // medium backdrop
        case enhancedGlass      // strong glass (alias)
        case darkGlass          // dark variant
        case darkGlassOverlay   // dark variant with boosted fill for overlay containers

        // Opacity-based glass
        case ultraStrong        // ultraStrong glass
        case strong             // strong glass
        case medium             // medium glass
        case subtle             // subtle glass
        case ultraLight         // ultraLight glass

        // Opacity-based backdrop
        case ultraStrongBackdrop
        case strongBackdrop
        case ultraLightBackdrop

        /// Convert to unified style parameters
        var unifiedStyle: UnifiedGlassButtonStyle {
            switch self {
            case .standard, .medium:
                return UnifiedGlassButtonStyle(opacity: .medium, variant: .glass)
            case .backdrop:
                return UnifiedGlassButtonStyle(opacity: .medium, variant: .backdrop)
            case .enhancedGlass, .strong:
                return UnifiedGlassButtonStyle(opacity: .strong, variant: .glass)
            case .darkGlass:
                return UnifiedGlassButtonStyle(opacity: .strong, variant: .dark)
            case .darkGlassOverlay:
                return UnifiedGlassButtonStyle(opacity: .strong, variant: .darkOverlay)
            case .ultraStrong:
                return UnifiedGlassButtonStyle(opacity: .ultraStrong, variant: .glass)
            case .subtle:
                return UnifiedGlassButtonStyle(opacity: .subtle, variant: .glass)
            case .ultraLight:
                return UnifiedGlassButtonStyle(opacity: .ultraLight, variant: .glass)
            case .ultraStrongBackdrop:
                return UnifiedGlassButtonStyle(opacity: .ultraStrong, variant: .backdrop)
            case .strongBackdrop:
                return UnifiedGlassButtonStyle(opacity: .strong, variant: .backdrop)
            case .ultraLightBackdrop:
                return UnifiedGlassButtonStyle(opacity: .ultraLight, variant: .backdrop)
            }
        }
    }

    init(_ title: String, isLoading: Bool = false, style: GlassStyle = .standard, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: isLoading ? {} : action) {
            ZStack {
                // Title text — always visible
                Text(title)

                // Right-side progress indicator during loading
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                    }
                    .padding(.horizontal, SpacingSystem.Size.lg)
                }
            }
        }
        .buttonStyle(style.unifiedStyle)
        .disabled(isLoading)
        .overlay(shimmerOverlay)
    }

    // MARK: - Loading State

    @ViewBuilder
    private var shimmerOverlay: some View {
        if isLoading {
            GlassShimmerEffect.matching(
                glassStyle: style,
                isAnimating: isLoading
            )
            .clipShape(RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge))
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
    }
}

// MARK: - Backward Compatibility Typealiases

/// Legacy style names - all map to UnifiedGlassButtonStyle internally
typealias GlassButtonStyle = UnifiedGlassButtonStyle
typealias BackdropGlassButtonStyle = UnifiedGlassButtonStyle
typealias UltraStrongGlassButtonStyle = UnifiedGlassButtonStyle
typealias DarkGlassButtonStyle = UnifiedGlassButtonStyle
typealias UltraStrongBackdropGlassButtonStyle = UnifiedGlassButtonStyle
typealias StrongGlassButtonStyle = UnifiedGlassButtonStyle
typealias MediumGlassButtonStyle = UnifiedGlassButtonStyle
typealias StrongBackdropGlassButtonStyle = UnifiedGlassButtonStyle
typealias UltraLightGlassButtonStyle = UnifiedGlassButtonStyle
typealias SubtleGlassButtonStyle = UnifiedGlassButtonStyle
typealias UltraLightBackdropGlassButtonStyle = UnifiedGlassButtonStyle

// Bandz prefixed versions
typealias BandzGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzBackdropGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzUltraStrongGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzDarkGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzUltraStrongBackdropGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzStrongGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzMediumGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzStrongBackdropGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzUltraLightGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzSubtleGlassButtonStyle = UnifiedGlassButtonStyle
typealias BandzUltraLightBackdropGlassButtonStyle = UnifiedGlassButtonStyle

// MARK: - ButtonStyle Extensions for Convenience

extension ButtonStyle where Self == UnifiedGlassButtonStyle {
    /// Standard glass button style
    static var bandzGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .medium, variant: .glass)
    }

    /// Backdrop glass button style
    static var bandzBackdropGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .medium, variant: .backdrop)
    }

    /// Dark glass button style
    static var bandzDarkGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .strong, variant: .dark)
    }

    /// Strong glass button style
    static var bandzStrongGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .strong, variant: .glass)
    }

    /// Medium glass button style
    static var bandzMediumGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .medium, variant: .glass)
    }

    /// Ultra strong glass button style
    static var bandzUltraStrongGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .ultraStrong, variant: .glass)
    }

    /// Subtle glass button style
    static var bandzSubtleGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .subtle, variant: .glass)
    }

    /// Ultra light glass button style
    static var bandzUltraLightGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .ultraLight, variant: .glass)
    }

    /// Strong backdrop glass button style
    static var bandzStrongBackdropGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .strong, variant: .backdrop)
    }

    /// Ultra strong backdrop glass button style
    static var bandzUltraStrongBackdropGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .ultraStrong, variant: .backdrop)
    }

    /// Ultra light backdrop glass button style
    static var bandzUltraLightBackdropGlass: UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: .ultraLight, variant: .backdrop)
    }

    /// Custom glass style with specific opacity and variant
    static func glass(_ opacity: GlassOpacity, variant: GlassVariant = .glass) -> UnifiedGlassButtonStyle {
        UnifiedGlassButtonStyle(opacity: opacity, variant: variant)
    }
}

// MARK: - Previews

#Preview("Consolidated Glass Styles") {
    ZStack {
        ColorSystem.Gradient.backgroundPrimary
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: SpacingSystem.Size.md) {
                Text("Unified Glass Button Styles")
                    .textStyle(Typography.TextStyle.h2, color: .white, alignment: .center)
                    .padding(.bottom, SpacingSystem.Size.sm)

                ForEach(GlassOpacity.allCases, id: \.self) { opacity in
                    VStack(spacing: SpacingSystem.Size.xs) {
                        Text("\(String(describing: opacity).uppercased())")
                            .textStyle(Typography.TextStyle.caption, color: .white.opacity(0.6), alignment: .center)

                        Button("\(String(describing: opacity).capitalized) Glass") { }
                            .buttonStyle(.glass(opacity))

                        Button("\(String(describing: opacity).capitalized) Backdrop") { }
                            .buttonStyle(.glass(opacity, variant: .backdrop))
                    }
                }

                Divider().background(Color.white.opacity(0.2))

                Text("Using BandzGlassButton")
                    .textStyle(Typography.TextStyle.caption, color: .white.opacity(0.6), alignment: .center)

                BandzGlassButton("Standard", style: .standard) { }
                BandzGlassButton("Strong", style: .strong) { }
                BandzGlassButton("Loading...", isLoading: true, style: .medium) { }
            }
            .padding(.horizontal, SpacingSystem.Size.lg)
            .padding(.vertical, SpacingSystem.Size.xl)
        }
    }
}

#Preview("Vibrant Background Test") {
    ZStack {
        LinearGradient(
            colors: [.teal, .green, .yellow, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: SpacingSystem.Size.lg) {
            Text("bandz")
                .textStyle(Typography.TextStyle.displayXLargeFutura, color: .black, alignment: .center)

            VStack(spacing: SpacingSystem.Size.sm) {
                BandzGlassButton("Ultra Strong", style: .ultraStrong) { }
                BandzGlassButton("Dark Glass", style: .darkGlass) { }
                BandzGlassButton("Strong Backdrop", style: .strongBackdrop) { }
            }
            .padding(.horizontal, SpacingSystem.Size.xl)
        }
    }
}
