//
//  GlassBackgroundModifier.swift
//  Bandz
//
//  Unified frosted glass background system.
//  Provides a reusable modifier for the layered glass aesthetic
//  (tint -> ultraThinMaterial -> border -> shadow) used across the app.
//

import SwiftUI

// MARK: - Glass Tint Presets

/// Predefined tint colors for the glass background
enum GlassTint {
    /// Brand-colored tint (white in dark, indigo in light) over ultraThinMaterial
    case brand
    /// Warm translucent tint — no material layer, lets gradient backgrounds show through.
    /// Use on cards over gradient backgrounds where `.brand` looks too gray/cold.
    case warmBrand
    /// Red-tinted glass for error states
    case error
    /// Green-tinted glass for success states
    case success
    /// Custom tint color
    case custom(Color)
}

// MARK: - Glass Shadow Presets

/// Predefined shadow configurations for the glass background
enum GlassShadow {
    /// Light shadow for bottom bars / pills (radius: 8, y: 4)
    case pill
    /// Heavy shadow for floating dialogs (radius: 30, y: 15)
    case dialog
    /// No shadow
    case none
    /// Custom shadow parameters
    case custom(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
}

// MARK: - Glass Background Modifier

struct GlassBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: GlassTint
    let borderWidth: CGFloat
    let shadow: GlassShadow

    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(
                shape.fill(tintColor)
                    .background(materialBackground(shape: shape))
                    .overlay(
                        shape.stroke(borderColor, lineWidth: borderWidth)
                    )
                    .modifier(ShadowModifier(shadow: shadow))
            )
    }

    @ViewBuilder
    private func materialBackground(shape: RoundedRectangle) -> some View {
        switch tint {
        case .warmBrand:
            shape.fill(warmFillColor)
        default:
            shape.fill(.ultraThinMaterial)
                .saturation(materialSaturation)
        }
    }

    private var warmFillColor: Color {
        colorScheme == .dark
            ? ColorSystem.System.surface1.opacity(0.70)
            : Color.white.opacity(0.30)
    }

    // MARK: - Material Saturation

    private var materialSaturation: Double {
        colorScheme == .dark ? 1.0 : 1.8
    }

    // MARK: - Tint Color

    private var tintColor: Color {
        switch tint {
        case .brand:
            return colorScheme == .dark
                ? Color.white.opacity(0.08)
                : ColorSystem.Brand.primary.opacity(0.10)
        case .warmBrand:
            return colorScheme == .dark
                ? Color.white.opacity(0.06)
                : ColorSystem.Brand.primary.opacity(0.06)
        case .error:
            return colorScheme == .dark
                ? Color.red.opacity(0.12)
                : ColorSystem.System.error.opacity(0.10)
        case .success:
            return colorScheme == .dark
                ? Color.green.opacity(0.12)
                : ColorSystem.System.success.opacity(0.10)
        case .custom(let color):
            return color.opacity(0.10)
        }
    }

    // MARK: - Border Color

    private var borderColor: Color {
        switch tint {
        case .brand:
            return colorScheme == .dark
                ? Color.white.opacity(0.08)
                : ColorSystem.Brand.primary.opacity(0.12)
        case .warmBrand:
            return colorScheme == .dark
                ? Color.white.opacity(0.08)
                : ColorSystem.Brand.primary.opacity(0.08)
        case .error:
            return colorScheme == .dark
                ? Color.red.opacity(0.20)
                : ColorSystem.System.error.opacity(0.20)
        case .success:
            return colorScheme == .dark
                ? Color.green.opacity(0.20)
                : ColorSystem.System.success.opacity(0.20)
        case .custom(let color):
            return color.opacity(0.15)
        }
    }
}

// MARK: - Shadow Modifier

private struct ShadowModifier: ViewModifier {
    let shadow: GlassShadow

    func body(content: Content) -> some View {
        switch shadow {
        case .pill:
            content.shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        case .dialog:
            content.shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 15)
        case .none:
            content
        case .custom(let color, let radius, let x, let y):
            content.shadow(color: color, radius: radius, x: x, y: y)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies a unified frosted glass background with configurable tint and shadow.
    func glassBackground(
        cornerRadius: CGFloat = SpacingSystem.CornerRadius.large,
        tint: GlassTint = .brand,
        borderWidth: CGFloat = 0.5,
        shadow: GlassShadow = .pill
    ) -> some View {
        modifier(GlassBackgroundModifier(
            cornerRadius: cornerRadius,
            tint: tint,
            borderWidth: borderWidth,
            shadow: shadow
        ))
    }
}
