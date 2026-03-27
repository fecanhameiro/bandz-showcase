import SwiftUI

/// Sistema de cores para padronização em toda a aplicação
///
/// Este sistema encapsula todas as cores da aplicação seguindo a estrutura
/// organizada do Assets.xcassets, oferecendo uma API consistente e semântica.
public enum ColorSystem {
    
    // MARK: - Brand Colors (Colors/Brand/)
    /// Cores principais da marca Bandz
    public struct Brand {
        /// Cor primária Indigo (#4F46E5 light / #818CF8 dark)
        public static let primary = Color("Brand/Primary")

        /// Teal accent (legacy, disponível como variação)
        public static let green = Color("Brand/PrimaryGreen")

        /// Blue accent (legacy, disponível como variação)
        public static let blue = Color("Brand/PrimaryBlue")

        /// Cor secundária Hot Pink (#EF2D82 light / #FF459B dark)
        public static let secondary = Color("Brand/Secondary")

        /// Dourado da marca (#C9A55A) — "disco de ouro"
        public static let gold = Color("Brand/Gold")

        // MARK: Variações da marca
        /// Variação clara da cor primária
        public static let primaryLight = primary.opacity(0.8)

        /// Variação escura da cor primária
        public static let primaryDark = primary.opacity(1.2)

        /// Variação suave do Indigo para bordas/ícones/estados no light mode
        /// (#6366F1 light / #818CF8 dark — mesmo que primary no dark)
        public static let primarySoft = Color("Brand/PrimarySoft")

        /// Variação muito clara para backgrounds sutis
        public static let primaryUltraLight = primary.opacity(0.1)
    }
    
    // MARK: - Text Colors (Colors/Text/)
    /// Cores para textos
    public struct Text {
        /// Texto primário (#212121 light / #FFFFFF dark)
        public static let primary = Color("Text/TextPrimary")
        
        /// Texto secundário
        public static let secondary = Color("Text/TextSecondary")
        
        /// Texto terciário (com opacidade)
        public static let tertiary = Color("Text/TextSecondary").opacity(0.7)
        
        /// Texto invertido para fundos escuros
        public static let inverse = Color("Text/TextSecondary")
        
        /// Texto de links
        public static let link = Brand.primary
        
        public static let accent = Color("Text/TextAccent")
        
        /// Texto de subtítulo/hashtags - mais sutil que o primário
        public static let subtitle = primary.opacity(0.6)
    }
    

    // MARK: - Gradient Colors (Colors/Gradient/)
    /// Cores para gradientes organizadas por propósito
    public struct Gradient {
        
        // MARK: Background Gradients
        /// Gradiente de fundo principal do app
        public static let backgroundPrimary = LinearGradient(
            colors: [
                Color("Gradient/GradientPrimaryStart"),
                Color("Gradient/GradientPrimaryMid1"),
                Color("Gradient/GradientPrimaryMid2"),
                Color("Gradient/GradientPrimaryMid3"),
                Color("Gradient/GradientPrimaryEnd")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// Gradiente de fundo para onboarding
        public static let backgroundOnboarding = LinearGradient(
            colors: [
                Color("Gradient/GradientOnboardingStart"),
                Color("Gradient/GradientOnboardingMid1"),
                Color("Gradient/GradientOnboardingMid2"),
                Color("Gradient/GradientOnboardingMid3"),
                Color("Gradient/GradientOnboardingEnd")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        /// Gradiente de fundo secundário
        public static let backgroundSecondary = LinearGradient(
            colors: [
                Color("Gradient/GradientSecondaryTopLeading"),
                Color("Gradient/GradientSecondaryBottomTrailing")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let brand = LinearGradient(
            colors: [
                Color("Gradient/GradientPrimaryStart"),
                Color("Gradient/GradientPrimaryMid1"),
                Color("Gradient/GradientPrimaryMid2"),
                Color("Gradient/GradientPrimaryMid3"),
                Color("Gradient/GradientPrimaryEnd")
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        
        /// Gradiente horizontal da marca (Indigo → Hot Pink)
        public static func brandHorizontal(opacity: Double = 1.0) -> LinearGradient {
            LinearGradient(
                colors: [
                    Brand.primary.opacity(opacity),
                    Brand.secondary.opacity(opacity)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        // MARK: Legacy gradients (mantidos para compatibilidade)
        /// Gradiente padrão do app (alias para backgroundPrimary)
        public static let primary = backgroundPrimary
        
        /// Gradiente específico para onboarding (alias para backgroundOnboarding)
        public static let onboarding = backgroundOnboarding
        
        /// Gradiente secundário para variação (alias para backgroundSecondary)
        public static let secondary = backgroundSecondary
        
        /// Gradiente vertical da cor primária
        public static func primaryVertical(opacity: Double = 1.0) -> LinearGradient {
            LinearGradient(
                colors: [
                    Color("Gradient/GradientPrimaryStart").opacity(opacity),
                    Color("Gradient/GradientPrimaryEnd").opacity(opacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        
        /// Gradiente horizontal da cor primária
        public static func primaryHorizontal(opacity: Double = 1.0) -> LinearGradient {
            LinearGradient(
                colors: [
                    Color("Gradient/GradientPrimaryStart").opacity(opacity),
                    Color("Gradient/GradientPrimaryEnd").opacity(opacity)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        // NOTA: Métodos "adaptive" removidos pois são desnecessários.
        // As cores do Colors.xcassets já mudam automaticamente com o tema do sistema.
        // Usar diretamente: ColorSystem.Gradient.backgroundOnboarding, etc.
    }
    
    // MARK: - System Colors (Colors/System/)
    /// Cores de sistema, estados e variações
    public struct System {
        /// Accent color (matches Brand.primary)
        public static let accent = Color("System/Accent")

        /// Header row com transparência
        public static let headerRow = Color("System/HeaderRow")

        public static let background = Color("System/Background")

        /// Content area background — warm beige (light) / dark slate (dark)
        /// Used as the main scrollable content background below hero sections.
        public static let contentBackground = Color("System/ContentBackground")

        // MARK: Elevation Surfaces (Dark Mode hierarchy)
        /// Surface 1 — Cards, event cards (#F5F5F5 light / #212121 dark)
        public static let surface1 = Color("System/Surface1")

        /// Surface 2 — Sheets, modals (#EEEEEE light / #2A2A2A dark)
        public static let surface2 = Color("System/Surface2")

        /// Surface 3 — Popovers, menus (#E5E5E5 light / #333333 dark)
        public static let surface3 = Color("System/Surface3")
        
        /// Background para botões glass - adaptativo light/dark theme
        /// Light: branco com 20% opacidade, Dark: Indigo #818CF8 com 60% opacidade
        public static let buttonGlassBackground = Color("System/ButtonGlassBackground")

        /// Sombra para botões glass - adaptativo light/dark theme
        /// Light: preto com 10% opacidade, Dark: Indigo #6366F1 com 100% opacidade
        public static let buttonGlassShadow = Color("System/ButtonGlassShadow")

        // MARK: Variações de opacidade
        /// Primário 50% opacidade (Indigo)
        public static let primaryGreen50 = Color("System/PrimaryGreen50")

        /// Primário 20% opacidade (Indigo)
        public static let primaryGreen20 = Color("System/PrimaryGreen20")
        
        // MARK: Estados desabilitados
        /// Primário desabilitado (Indigo com opacidade reduzida)
        public static let primaryGreenDisabled = Color("System/PrimaryGreenDisabled")

        /// Alternativo desabilitado (Indigo com opacidade reduzida)
        public static let greenDisabled = Color("System/GreenDisabled")
        
        /// Gray alternativo desabilitado
        public static let tabItemInactive = Color("System/TabItemInactive")
        
        // MARK: Estados de feedback
        /// Sucesso
        public static let success = Color("Feedback/Success")
        public static let successBackground = Color("Feedback/SuccessBackground")
        public static let successBorder = Color("Feedback/SuccessBorder")
        
        /// Aviso
        public static let warning = Color.orange
        
        /// Erro
        public static let error = Color("Feedback/Error")
        public static let errorBackground = Color("Feedback/ErrorBackground")
        public static let errorBorder = Color("Feedback/ErrorBorder")
        
        /// Informação
        public static let info = Color("Feedback/Info")
        public static let infoBackground = Color("Feedback/InfoBackground")
        public static let infoBorder = Color("Feedback/InfoBorder")
        
        // MARK: Estados de interface
        /// Desabilitado
        public static let disabled = Color.gray.opacity(0.5)
        
        /// Ativo/selecionado
        public static let active = Brand.primary
        
        /// Pressionado
        public static let pressed = Brand.primary.opacity(0.8)
        
        /// Hover (Mac Catalyst)
        public static let hover = Brand.primary.opacity(0.6)
    }
    
    // MARK: - Utility Colors
    /// Cores utilitárias
    public struct Utility {
        /// Transparente
        public static let clear = Color.clear
        
        /// Separador/divider padrão
        public static let divider = Color.gray.opacity(0.3)
        
        /// Overlay para modais/sheets
        public static let overlay = Color.black.opacity(0.4)
        
        /// Sombra padrão
        public static let shadow = Color.black.opacity(0.1)
    }
    
    // MARK: - Legacy Support
    /// Cores principais do app (compatibilidade com código antigo)
    public struct Primary {
        /// Cor primária principal
        public static let base = Brand.primary
        
        /// Variação clara da cor primária
        public static let light = Brand.primaryLight
        
        /// Variação escura da cor primária
        public static let dark = Brand.primaryDark
        
        /// Variação muito clara para backgrounds sutis
        public static let ultraLight = Brand.primaryUltraLight
    }
    
    /// Cores secundárias do app (compatibilidade com código antigo)
    public struct Secondary {
        /// Cor secundária principal
        public static let base = Brand.secondary
        
        /// Variação clara da cor secundária
        public static let light = Brand.secondary.opacity(0.8)
        
        /// Variação escura da cor secundária
        public static let dark = Brand.secondary.opacity(1.2)
        
        /// Variação muito clara para backgrounds sutis
        public static let ultraLight = Brand.secondary.opacity(0.1)
    }
    
    /// Cores para estados e feedbacks (compatibilidade com código antigo)
    public struct Feedback {
        /// Cor para sucesso e ações positivas
        public static let success = System.success
        public static let successBackground = System.successBackground
        public static let successBorder = System.successBorder
        /// Cor para alertas e avisos
        public static let warning = System.warning
        
        /// Cor para erros e ações negativas
        public static let error = System.error
        public static let errorBackground = System.errorBackground
        public static let errorBorder = System.errorBorder
        
        /// Cor para informações e notificações
        public static let info = System.info
        public static let infoBackground = System.infoBackground
        public static let infoBorder = System.infoBorder
    }
    
    /// Cores para estados de interface (compatibilidade com código antigo)
    public struct State {
        /// Estado desabilitado
        public static let disabled = System.disabled
        
        /// Estado ativo/selecionado
        public static let active = System.active
        
        /// Estado pressionado
        public static let pressed = System.pressed
        
        /// Estado hover (para Mac Catalyst)
        public static let hover = System.hover
    }
    
    public struct Icon {
        public static let primary = Color("Icons/Primary")
        
        public static let backgroundPrimary = Color("Icons/BackgroundPrimary")
    }
    
    public struct EventCard {
        public static let textPrimary = Color("EventCard/TextPrimary")
        public static let background = Color("EventCard/Background")
        
        public struct Button {
            public static let textWhite = Color("EventCard/Button/TextWhite")
            public static let textAccent = Color("EventCard/Button/TextAccent")
            public static let backgroundBlack = Color("EventCard/Button/BackgroundBlack")
            public static let backgroundAccent = Color("EventCard/Button/BackgroundAccent")
        }
    }
}

// MARK: - Tipos de gradiente para componentes
public enum BandzGradientType {
    case backgroundPrimary       // Gradiente de fundo principal
    case backgroundOnboarding    // Gradiente de fundo do onboarding
    case backgroundSecondary     // Gradiente de fundo secundário
    case brand                   // Gradiente da marca
    case primary                 // Legacy: alias para backgroundPrimary
    case onboarding             // Legacy: alias para backgroundOnboarding
    case secondary              // Legacy: alias para backgroundSecondary
    case custom([Color])         // Gradiente customizado a partir de um array de cores
    
    /// Retorna a view de gradiente estático correspondente.
    public var gradient: LinearGradient {
        switch self {
            case .backgroundPrimary, .primary:
                return ColorSystem.Gradient.backgroundPrimary
            case .backgroundOnboarding, .onboarding:
                return ColorSystem.Gradient.backgroundOnboarding
            case .backgroundSecondary, .secondary:
                return ColorSystem.Gradient.backgroundSecondary
            case .brand:
                return ColorSystem.Gradient.brand
            case .custom(let colors):
                // Constrói um gradiente padrão com as cores customizadas.
                return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    /// Retorna o array de cores para o tipo de gradiente, permitindo a reconstrução (ex: para animação).
    public var colors: [Color] {
        switch self {
            case .backgroundPrimary, .primary, .brand:
                return [
                    Color("Gradient/GradientPrimaryStart"),
                    Color("Gradient/GradientPrimaryMid1"),
                    Color("Gradient/GradientPrimaryMid2"),
                    Color("Gradient/GradientPrimaryMid3"),
                    Color("Gradient/GradientPrimaryEnd")
                ]
            case .backgroundOnboarding, .onboarding:
                return [
                    Color("Gradient/GradientOnboardingStart"),
                    Color("Gradient/GradientOnboardingMid1"),
                    Color("Gradient/GradientOnboardingMid2"),
                    Color("Gradient/GradientOnboardingMid3"),
                    Color("Gradient/GradientOnboardingEnd")
                ]
            case .backgroundSecondary, .secondary:
                return [
                    Color("Gradient/GradientSecondaryTopLeading"),
                    Color("Gradient/GradientSecondaryBottomTrailing")
                ]
            case .custom(let colors):
                // Retorna diretamente o array de cores associado.
                return colors
        }
    }
}

// MARK: - Extensões para facilitar uso
extension Color {
    /// Acesso rápido às cores da marca
    public static let bandzPrimary = ColorSystem.Brand.primary
    public static let bandzSecondary = ColorSystem.Brand.secondary
    public static let bandzGold = ColorSystem.Brand.gold
    public static let bandzGreen = ColorSystem.Brand.green
    public static let bandzBlue = ColorSystem.Brand.blue
}

extension LinearGradient {
    /// Gradientes prontos para uso
    public static let bandzBackground = ColorSystem.Gradient.backgroundPrimary
    public static let bandzOnboarding = ColorSystem.Gradient.backgroundOnboarding
    public static let bandzBrand = ColorSystem.Gradient.brand
    
    // MARK: Legacy support
    /// Gradiente primário padrão do Bandz (compatibilidade)
    public static var primaryGradientBandz: LinearGradient {
        ColorSystem.Gradient.primary
    }
    
    /// Gradiente secundário do Bandz (compatibilidade)
    public static var secondaryGradientBandz: LinearGradient {
        ColorSystem.Gradient.secondary
    }
}

// MARK: - View modifiers para aplicar cores de forma semântica

/// Modificador para aplicar um estilo de foreground color semântico
struct ForegroundColorStyleModifier: ViewModifier {
    let style: ForegroundColorStyle
    
    init(_ style: ForegroundColorStyle) {
        self.style = style
    }
    
    func body(content: Content) -> some View {
        content.foregroundColor(style.color)
    }
}

/// Modificador para aplicar um estilo de background semântico
struct BackgroundColorStyleModifier: ViewModifier {
    let style: BackgroundColorStyle
    
    init(_ style: BackgroundColorStyle) {
        self.style = style
    }
    
    func body(content: Content) -> some View {
        content.background(style.background)
    }
}

/// Estilos de cor de foreground disponíveis
public enum ForegroundColorStyle {
    case primary
    case secondary
    case accent
    case tertiary
    case inverse
    case link
    case success
    case warning
    case error
    case info
    case disabled
    case eventCardPrimary
    case custom(Color)
    
    var color: Color {
        switch self {
            case .primary:
                return ColorSystem.Text.primary
            case .secondary:
                return ColorSystem.Text.secondary
            case .tertiary:
                return ColorSystem.Text.tertiary
            case .inverse:
                return ColorSystem.Text.inverse
            case .link:
                return ColorSystem.Text.link
            case .success:
                return ColorSystem.System.success
            case .warning:
                return ColorSystem.System.warning
            case .error:
                return ColorSystem.System.error
            case .info:
                return ColorSystem.System.info
            case .disabled:
                return ColorSystem.System.disabled
            case .eventCardPrimary:
                return ColorSystem.EventCard.textPrimary
            case .custom(let color):
                return color
            case .accent:
                return ColorSystem.Brand.primary
        }
    }
}

/// Estilos de cor de background disponíveis
public enum BackgroundColorStyle {
    case accent
    case primaryGradient
    case secondaryGradient
    case success
    case warning
    case error
    case info
    case disabled
    case clear
    case custom(Color)
    case customGradient(LinearGradient)
    
    var background: some View {
        switch self {
            case .accent:
                return AnyView(ColorSystem.Brand.primary)
            case .primaryGradient:
                return AnyView(ColorSystem.Gradient.primary)
            case .secondaryGradient:
                return AnyView(ColorSystem.Gradient.secondary)
            case .success:
                return AnyView(ColorSystem.System.success)
            case .warning:
                return AnyView(ColorSystem.System.warning)
            case .error:
                return AnyView(ColorSystem.System.error)
            case .info:
                return AnyView(ColorSystem.System.info)
            case .disabled:
                return AnyView(ColorSystem.System.disabled)
            case .clear:
                return AnyView(ColorSystem.Utility.clear)
            case .custom(let color):
                return AnyView(color)
            case .customGradient(let gradient):
                return AnyView(gradient)
        }
    }
}

// MARK: - Adaptive Color System
/// Sistema adaptativo que considera o tema atual do device/app
public enum AdaptiveColorSystem {
    
    // MARK: - Current Theme Access
    /// Acesso às cores do tema atual considerando o ColorScheme do ambiente
    public struct Current {
        private let colorScheme: ColorScheme
        
        public init(for colorScheme: ColorScheme) {
            self.colorScheme = colorScheme
        }
        
        // MARK: - Adaptive Text Colors
        public var textPrimary: Color {
            ColorSystem.Text.primary // Já adaptativo via xcassets
        }
        
        public var textSecondary: Color {
            ColorSystem.Text.secondary // Já adaptativo via xcassets
        }
        
        public var textAccent: Color {
            ColorSystem.Text.accent // Já adaptativo via xcassets
        }
        
        
        // MARK: - Adaptive Brand Colors
        public var brandPrimary: Color {
            ColorSystem.Brand.primary // Já adaptativo via xcassets
        }
        
        public var brandSecondary: Color {
            ColorSystem.Brand.secondary
        }
        
        // NOTA: Métodos de gradientes adaptativos removidos pois são desnecessários.
        // Os gradientes do ColorSystem.Gradient já usam cores adaptativas via xcassets.
        // Usar diretamente: ColorSystem.Gradient.backgroundOnboarding, etc.
        
        // MARK: - Foreground Style Resolution
        public func foregroundColor(for style: ForegroundColorStyle) -> Color {
            switch style {
                case .primary:
                    return textPrimary
                case .secondary:
                    return textSecondary
                case .accent:
                    return textAccent
                case .tertiary:
                    return ColorSystem.Text.tertiary
                case .inverse:
                    return colorScheme == .dark ? ColorSystem.Text.primary : ColorSystem.Text.inverse
                case .link:
                    return ColorSystem.Text.link
                case .success:
                    return ColorSystem.System.success
                case .warning:
                    return ColorSystem.System.warning
                case .error:
                    return ColorSystem.System.error
                case .info:
                    return ColorSystem.System.info
                case .disabled:
                    return ColorSystem.System.disabled
                case .eventCardPrimary:
                    return ColorSystem.EventCard.textPrimary
                case .custom(let color):
                    return color
            }
        }
        
        // MARK: - Background Style Resolution
        @ViewBuilder
        public func background(for style: BackgroundColorStyle) -> some View {
            switch style {
                case .accent:
                    brandPrimary
                case .primaryGradient:
                    ColorSystem.Gradient.backgroundPrimary
                case .secondaryGradient:
                    ColorSystem.Gradient.backgroundSecondary
                case .success:
                    ColorSystem.System.success
                case .warning:
                    ColorSystem.System.warning
                case .error:
                    ColorSystem.System.error
                case .info:
                    ColorSystem.System.info
                case .disabled:
                    ColorSystem.System.disabled
                case .clear:
                    ColorSystem.Utility.clear
                case .custom(let color):
                    color
                case .customGradient(let gradient):
                    gradient
            }
        }
    }
    
    // MARK: - Static Access Methods
    /// Cria uma instância Current baseada no ColorScheme fornecido
    public static func current(for colorScheme: ColorScheme) -> Current {
        Current(for: colorScheme)
    }
}


// MARK: - Extensões para View

public extension View {
    /// Aplica uma cor de texto semântica (versão original - mantida para compatibilidade)
    func bandzForegroundStyle(_ style: ForegroundColorStyle = .primary) -> some View {
        self.modifier(ForegroundColorStyleModifier(style))
    }
    
    /// Aplica uma cor/gradiente de fundo semântico (versão original - mantida para compatibilidade)
    func bandzBackgroundStyle(_ style: BackgroundColorStyle) -> some View {
        self.modifier(BackgroundColorStyleModifier(style))
    }

    /// Brand glow effect — "stage light" shadow using brand colors. Active only in dark mode.
    func brandGlow(
        isActive: Bool = true,
        color: Color = ColorSystem.Brand.primary,
        radius: CGFloat = 12
    ) -> some View {
        self.shadow(
            color: isActive ? color.opacity(0.35) : .clear,
            radius: radius, x: 0, y: 0
        )
    }
}
