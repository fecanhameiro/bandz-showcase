//
// BandzThemeController.swift
// Bandz
//
// A centralized controller for applying the design system throughout the app.
//

import SwiftUI
import Observation

// Import other design system components - already defined in files

/// Controls the application's theming and provides utilities for applying the design system
@MainActor
@Observable
public final class BandzThemeController {
    public static let shared = BandzThemeController()

    public var colorScheme: ColorScheme = .light {
        didSet { userDefaults.set(colorScheme == .dark ? "dark" : "light", forKey: "userColorScheme") }
    }
    public var fontSize: FontSize = .medium {
        didSet { userDefaults.set(fontSize.rawValue, forKey: "userFontSize") }
    }
    public var hapticFeedbackEnabled: Bool = true {
        didSet { userDefaults.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled") }
    }

    @ObservationIgnored private let userDefaults = UserDefaults.standard
    
    public enum FontSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var scaleFactor: CGFloat {
            switch self {
                case .small: return 0.9
                case .medium: return 1.0
                case .large: return 1.2
            }
        }
    }
    
    private init() {
        loadSavedSettings()
    }

    private func loadSavedSettings() {
        if let savedScheme = userDefaults.string(forKey: "userColorScheme"),
           savedScheme == "dark" {
            colorScheme = .dark
        } else if let savedScheme = userDefaults.string(forKey: "userColorScheme"),
                  savedScheme == "light" {
            colorScheme = .light
        } else {
            // Use system default
            colorScheme = .light
        }
        
        if let savedFontSize = userDefaults.string(forKey: "userFontSize"),
           let fontSizeEnum = FontSize(rawValue: savedFontSize) {
            fontSize = fontSizeEnum
        }
        
        hapticFeedbackEnabled = userDefaults.bool(forKey: "hapticFeedbackEnabled")
    }

    // MARK: - Feedback Methods

    /// Generates haptic feedback if enabled
    public func generateHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticFeedbackEnabled else { return }
        HapticManager.shared.impact(style: style)
    }

    /// Generates selection feedback if enabled
    public func generateSelectionFeedback() {
        guard hapticFeedbackEnabled else { return }
        HapticManager.shared.selection()
    }

    /// Generates notification feedback if enabled
    public func generateNotificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticFeedbackEnabled else { return }
        HapticManager.shared.notify(type)
    }
    
    // MARK: - Theme Utilities
    
    /// Applies the font size scaling to a given base size
    public func scaledFontSize(_ baseSize: CGFloat) -> CGFloat {
        return baseSize * fontSize.scaleFactor
    }
    
    /// Gets the appropriate corner radius based on component size
    public func cornerRadius(for size: String) -> CGFloat {
        switch size {
            case "small":
                return SpacingSystem.CornerRadius.small
            case "medium":
                return SpacingSystem.CornerRadius.medium
            case "large":
                return SpacingSystem.CornerRadius.large
            default:
                return SpacingSystem.CornerRadius.medium
        }
    }
    
    /// Gets the appropriate shadow based on elevation level
    public func shadow(for elevation: ElevationSystem.Level) -> Shadow {
        switch elevation {
            case .none:
                return Shadow(color: Color.black.opacity(0.0), radius: 0, x: 0, y: 0)
            case .subtle:
                return Shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            case .medium:
                return Shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            case .high:
                return Shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            case .highest:
                return Shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 8)
        }
    }
    
    /// Gets responsive padding based on device size
    public func responsivePadding() -> EdgeInsets {
        let deviceWidth = UIScreen.main.bounds.width
        
        if deviceWidth >= 744 { // iPad
            return EdgeInsets(
                top: SpacingSystem.Size.lg,
                leading: SpacingSystem.Size.xl,
                bottom: SpacingSystem.Size.lg,
                trailing: SpacingSystem.Size.xl
            )
        } else { // iPhone
            return EdgeInsets(
                top: SpacingSystem.Size.md,
                leading: SpacingSystem.Size.lg,
                bottom: SpacingSystem.Size.md,
                trailing: SpacingSystem.Size.lg
            )
        }
    }
}

// MARK: - Helper Structs

public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}

// MARK: - Environment Extensions

public extension View {
    func withThemeController() -> some View {
        self.environment(BandzThemeController.shared)
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply the appropriate font scaling based on user preferences
    func scaledFont(_ style: TextStyleConfiguration) -> some View {
        return self.modifier(ScaledFontModifier(style: style))
    }
    
    /// Apply the appropriate corner radius based on component size
    func bandzCornerRadius(_ size: String = "medium") -> some View {
        let controller = BandzThemeController.shared
        return self.cornerRadius(controller.cornerRadius(for: size))
    }
    
    /// Apply the appropriate shadow based on elevation level
    func bandzShadow(_ elevation: ElevationSystem.Level) -> some View {
        let shadow = BandzThemeController.shared.shadow(for: elevation)
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply responsive padding based on device size
    func bandzResponsivePadding() -> some View {
        let padding = BandzThemeController.shared.responsivePadding()
        return self.padding(padding)
    }
    
    /// Apply primary gradient background
    func primaryGradientBackground() -> some View {
        return self.background(
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color("GradientPrimaryTopLeading"),
                        Color("GradientPrimaryBottomTrailing")
                    ]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    /// Apply secondary gradient background
    func secondaryGradientBackground() -> some View {
        return self.background(
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color("GradientSecondaryTopLeading"),
                        Color("GradientSecondaryBottomTrailing")
                    ]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Modifiers

struct ScaledFontModifier: ViewModifier {
    let style: TextStyleConfiguration
    @SwiftUI.Environment(BandzThemeController.self) private var themeController: BandzThemeController?
    
    func body(content: Content) -> some View {
        let baseSize = style.size
        let controller = themeController ?? BandzThemeController.shared
        let scaledSize = controller.scaledFontSize(baseSize)

        return content
            .font(.system(size: scaledSize, weight: style.weight))
            .lineSpacing(scaledSize * (style.lineSpacing - 1))
    }
}
