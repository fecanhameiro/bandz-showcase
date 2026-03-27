import SwiftUI

/// Sistema de tipografia para padronização de textos em toda a aplicação
///
/// Este sistema define estilos de texto consistentes para diferentes
/// casos de uso, garantindo uma hierarquia visual clara e consistente.
/// Inclui tamanhos de 10pt até 64pt com line heights e spacing otimizados.
public enum Typography {
    /// Tamanhos de fonte padronizados
    public struct FontSize {
        /// 10 points - Micro texto para detalhes mínimos
        public static let micro: CGFloat = 10
        
        /// 12 points - Texto muito pequeno para footnotes
        public static let xSmall: CGFloat = 12
        
        /// 14 points - Texto pequeno para captions e labels
        public static let small: CGFloat = 14
        
        /// 16 points - Texto de corpo padrão (body)
        public static let body: CGFloat = 16
        
        /// 18 points - Texto médio para destaque em corpo
        public static let medium: CGFloat = 18
        
        /// 20 points - Texto grande para subtítulos
        public static let large: CGFloat = 20
        
        /// 22 points - Texto extra large
        public static let xLarge: CGFloat = 22
        
        /// 24 points - Título pequeno (h4)
        public static let xxLarge: CGFloat = 24
        
        /// 28 points - Título médio (h3)
        public static let xxxLarge: CGFloat = 28
        
        /// 32 points - Título grande (h2)
        public static let huge: CGFloat = 32
        
        /// 40 points - Título extra grande (h1)
        public static let xHuge: CGFloat = 40
        
        /// 48 points - Display médio para hero sections
        public static let display: CGFloat = 48
        
        /// 56 points - Display grande para títulos de destaque
        public static let displayLarge: CGFloat = 56
        
        /// 64 points - Display extra grande para títulos principais
        public static let displayXLarge: CGFloat = 64
        
        /// 72 points - Display máximo para casos especiais
        public static let displayHuge: CGFloat = 72
    }
    
    /// Pesos de fonte padronizados
    public struct FontWeight {
        public static let regular: Font.Weight = .regular
        public static let medium: Font.Weight = .medium
        public static let semibold: Font.Weight = .semibold
        public static let bold: Font.Weight = .bold
        public static let heavy: Font.Weight = .heavy
    }
    
    /// Sistema de escalas de linha consistentes
    /// Line heights são calculados como multiplicadores do tamanho da fonte
    public struct LineHeight {
        /// 1.0 - Sem espaçamento extra (para displays grandes)
        public static let none: CGFloat = 1.0
        
        /// 1.1 - Espaçamento mínimo (para títulos grandes e displays)
        public static let tight: CGFloat = 1.1
        
        /// 1.2 - Espaçamento compacto (para títulos médios)
        public static let compact: CGFloat = 1.2
        
        /// 1.25 - Espaçamento moderado (para títulos pequenos)
        public static let moderate: CGFloat = 1.25
        
        /// 1.4 - Espaçamento normal (para texto de interface)
        public static let normal: CGFloat = 1.4
        
        /// 1.5 - Espaçamento padrão para corpo de texto
        public static let comfortable: CGFloat = 1.5
        
        /// 1.6 - Espaçamento amplo para melhor legibilidade
        public static let loose: CGFloat = 1.6
        
        /// 1.75 - Espaçamento extra amplo
        public static let extraLoose: CGFloat = 1.75
        
        /// 2.0 - Espaçamento máximo (para textos muito pequenos)
        public static let maximum: CGFloat = 2.0
    }
    
    /// Sistema de espaçamento entre caracteres (letter spacing)
    public struct LetterSpacing {
        /// -0.5 - Espaçamento negativo para displays grandes
        public static let tight: CGFloat = -0.5
        
        /// -0.25 - Espaçamento ligeiramente negativo para títulos
        public static let compact: CGFloat = -0.25
        
        /// 0.0 - Sem espaçamento extra (padrão)
        public static let normal: CGFloat = 0.0
        
        /// 0.25 - Espaçamento ligeiramente positivo
        public static let loose: CGFloat = 0.25
        
        /// 0.5 - Espaçamento amplo para texto pequeno
        public static let wide: CGFloat = 0.5
        
        public static let xWide: CGFloat = 0.75
        
        public static let xxWide: CGFloat = 1.75
    }
    
    /// Estilos de texto predefinidos
    public struct TextStyle {
        // MARK: - Display Titles (64pt - 48pt)
        
        /// Display Extra Large - Títulos principais de hero (64pt, bold)
        public static let displayXLarge = TextStyleConfiguration(
            size: FontSize.displayXLarge,
            weight: .bold,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.xWide
        )
        
        /// Display Extra Large Futura - Títulos hero com fonte customizada (64pt, Futura PT Bold)
        public static let displayXLargeFutura = TextStyleConfiguration(
            size: FontSize.displayXLarge,
            weight: .bold,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.xxWide,
            customFontName: "FuturaPT-Bold"
        )
        
        public static let displayLargeFutura = TextStyleConfiguration(
            size: FontSize.displayLarge,
            weight: .bold,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.xxWide,
            customFontName: "FuturaPT-Bold"
        )
        
        /// Display Large - Títulos de destaque (56pt, bold)
        public static let displayLarge = TextStyleConfiguration(
            size: FontSize.displayLarge,
            weight: .bold,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.wide
        )
        
        /// Display - Hero sections e banners (48pt, bold)
        public static let display = TextStyleConfiguration(
            size: FontSize.display,
            weight: .bold,
            lineSpacing: LineHeight.compact,
            letterSpacing: LetterSpacing.compact
        )
        
        // MARK: - Hierarchy Titles (40pt - 20pt)

        /// Heading 1 - Títulos principais de tela (40pt, bold)
        public static let h1 = TextStyleConfiguration(
            size: FontSize.xHuge,
            weight: .bold,
            lineSpacing: LineHeight.compact,
            letterSpacing: LetterSpacing.compact
        )
        
        public static let h2Futura = TextStyleConfiguration(
            size: FontSize.huge,
            weight: .bold,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.xxWide,
            customFontName: "FuturaPT-Bold"
        )
        
        /// Heading 2 - Títulos secundários (32pt, bold)
        public static let h2 = TextStyleConfiguration(
            size: FontSize.huge,
            weight: .bold,
            lineSpacing: LineHeight.moderate,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Heading 3 - Títulos de seção (28pt, semibold)
        public static let h3 = TextStyleConfiguration(
            size: FontSize.xxxLarge,
            weight: .semibold,
            lineSpacing: LineHeight.moderate,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Heading 4 - Subtítulos (24pt, semibold)
        public static let h4 = TextStyleConfiguration(
            size: FontSize.xxLarge,
            weight: .semibold,
            lineSpacing: LineHeight.moderate,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Heading 5 - Títulos pequenos (24pt, regular)
        public static let h5 = TextStyleConfiguration(
            size: FontSize.xxLarge,
            weight: .regular,
            lineSpacing: LineHeight.normal,
            letterSpacing: LetterSpacing.xxWide
        )
        
        /// App Title Futura - Título do app com fonte Futura e espaçamento de 10% (24pt, Futura-Bold)
        public static let appTitleFutura = TextStyleConfiguration(
            size: FontSize.xxLarge,
            weight: .bold,
            lineSpacing: LineHeight.normal,
            letterSpacing: FontSize.xxLarge * 0.15, // 10% do tamanho da fonte
            customFontName: "Futura-Bold"
        )
        
        /// Subtitle Large - Subtítulos grandes (20pt, medium)
        public static let subtitleLarge = TextStyleConfiguration(
            size: FontSize.large,
            weight: .medium,
            lineSpacing: LineHeight.normal,
            letterSpacing: LetterSpacing.normal
        )
        
        public static let subtitleLargeSemiBold = TextStyleConfiguration(
            size: FontSize.large,
            weight: .semibold,
            lineSpacing: LineHeight.normal,
            letterSpacing: LetterSpacing.normal
        )
        
        public static let subtitleLargeXXWideSemiBold = TextStyleConfiguration(
            size: FontSize.xxLarge,
            weight: .semibold,
            lineSpacing: LineHeight.normal,
            letterSpacing: LetterSpacing.xxWide
        )
        
        /// Subtitle - Subtítulos padrão (18pt, medium)
        public static let subtitle = TextStyleConfiguration(
            size: FontSize.medium,
            weight: .medium,
            lineSpacing: LineHeight.normal,
            letterSpacing: LetterSpacing.normal
        )
        
        // MARK: - Body Text (16pt)
        
        /// Body Large - Texto de corpo grande (20pt, regular)
        public static let bodyLarge = TextStyleConfiguration(
            size: FontSize.large,
            weight: .regular,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.wide
        )
        
        /// Body Large - Texto de corpo grande (18pt, regular)
        public static let bodyMedium = TextStyleConfiguration(
            size: FontSize.medium,
            weight: .regular,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Body - Texto de corpo padrão (16pt, regular)
        public static let bodyRegular = TextStyleConfiguration(
            size: FontSize.body,
            weight: .regular,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Body Emphasized - Texto de corpo em destaque (16pt, medium)
        public static let bodyEmphasized = TextStyleConfiguration(
            size: FontSize.body,
            weight: .medium,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Body Bold - Texto de corpo em negrito (16pt, bold)
        public static let bodyBold = TextStyleConfiguration(
            size: FontSize.body,
            weight: .bold,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Body Large Emphasized - Texto de corpo em destaque (20pt, medium)
        public static let bodyLargeEmphasized = TextStyleConfiguration(
            size: FontSize.large,
            weight: .medium,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.xxWide
        )
        
        // MARK: - Supporting Text (14pt - 10pt)
        
        /// Caption Large - Legendas grandes (14pt, regular)
        public static let captionLarge = TextStyleConfiguration(
            size: FontSize.small,
            weight: .regular,
            lineSpacing: LineHeight.loose,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Caption - Legendas e informações secundárias (14pt, medium)
        public static let caption = TextStyleConfiguration(
            size: FontSize.small,
            weight: .medium,
            lineSpacing: LineHeight.loose,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Caption - Legendas e informações secundárias (14pt, bold)
        public static let captionBold = TextStyleConfiguration(
            size: FontSize.small,
            weight: .bold,
            lineSpacing: LineHeight.loose,
            letterSpacing: LetterSpacing.xWide
        )

        /// Caption Extra Bold - Texto compacto em negrito para títulos de cards (12pt, bold)
        public static let captionExtraBold = TextStyleConfiguration(
            size: FontSize.xSmall,
            weight: .bold,
            lineSpacing: LineHeight.loose,
            letterSpacing: LetterSpacing.wide
        )

        /// Hashtag - Texto para hashtags e subtítulos secundários (11pt, medium)
        public static let hashtag = TextStyleConfiguration(
            size: 11,
            weight: .medium,
            lineSpacing: LineHeight.normal,
            letterSpacing: LetterSpacing.normal
        )
        
        public static let hashtagBold = TextStyleConfiguration(
            size: 11,
            weight: .bold,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.normal
        )
        
        public static let hashtagLight = TextStyleConfiguration(
            size: 12,
            weight: .light,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Footnote - Texto muito pequeno para informações auxiliares (12pt, regular)
        public static let footnote = TextStyleConfiguration(
            size: FontSize.xSmall,
            weight: .regular,
            lineSpacing: LineHeight.loose,
            letterSpacing: LetterSpacing.loose
        )
        
        /// Footnote Emphasized - Footnote em destaque (12pt, medium)
        public static let footnoteEmphasized = TextStyleConfiguration(
            size: FontSize.xSmall,
            weight: .medium,
            lineSpacing: LineHeight.loose,
            letterSpacing: LetterSpacing.loose
        )
        
        /// Footnote Light - Texto muito pequeno para informações auxiliares (12pt, light)
        public static let footnoteLight = TextStyleConfiguration(
            size: FontSize.xSmall,
            weight: .light,
            lineSpacing: LineHeight.loose,
            letterSpacing: LetterSpacing.loose
        )
        
        /// Micro - Texto mínimo para detalhes (10pt, regular)
        public static let micro = TextStyleConfiguration(
            size: FontSize.micro,
            weight: .regular,
            lineSpacing: LineHeight.extraLoose,
            letterSpacing: LetterSpacing.wide
        )

        /// Micro Emphasized - Texto mínimo com destaque (10pt, medium)
        public static let microEmphasized = TextStyleConfiguration(
            size: FontSize.micro,
            weight: .medium,
            lineSpacing: LineHeight.extraLoose,
            letterSpacing: LetterSpacing.wide
        )

        public static let microLight = TextStyleConfiguration(
            size: FontSize.micro,
            weight: .light,
            lineSpacing: LineHeight.extraLoose,
            letterSpacing: LetterSpacing.wide
        )

        /// Nano Light - Texto minúsculo para informações muito secundárias (9pt, light)
        public static let nanoLight = TextStyleConfiguration(
            size: 9,
            weight: .light,
            lineSpacing: LineHeight.comfortable,
            letterSpacing: LetterSpacing.normal
        )

        // MARK: - Interactive Elements
        
        /// Button Extra Large - Botões de destaque (20pt, semibold)
        public static let buttonXLarge = TextStyleConfiguration(
            size: FontSize.large,
            weight: .semibold,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Button Large - Botões grandes (18pt, semibold)
        public static let buttonLarge = TextStyleConfiguration(
            size: FontSize.medium,
            weight: .bold,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.loose
        )
        
        /// Button Medium - Botões médios (16pt, semibold)
        public static let buttonMedium = TextStyleConfiguration(
            size: FontSize.body,
            weight: .regular,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.wide
        )
        
        /// Button Small - Botões pequenos (14pt, medium)
        public static let buttonSmall = TextStyleConfiguration(
            size: FontSize.small,
            weight: .medium,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Label - Labels de interface (14pt, medium)
        public static let label = TextStyleConfiguration(
            size: FontSize.small,
            weight: .medium,
            lineSpacing: LineHeight.normal,
            letterSpacing: LetterSpacing.normal
        )
        
        /// Tab Bar - Texto de tab bar (10pt, medium)
        public static let tabBar = TextStyleConfiguration(
            size: FontSize.micro,
            weight: .medium,
            lineSpacing: LineHeight.tight,
            letterSpacing: LetterSpacing.normal
        )
    }
}

/// Configuração para estilos de texto
public struct TextStyleConfiguration {
    let size: CGFloat
    let weight: Font.Weight
    let lineSpacing: CGFloat
    let letterSpacing: CGFloat
    let customFontName: String?
    
    public init(
        size: CGFloat,
        weight: Font.Weight,
        lineSpacing: CGFloat,
        letterSpacing: CGFloat = Typography.LetterSpacing.normal,
        customFontName: String? = nil
    ) {
        self.size = size
        self.weight = weight
        self.lineSpacing = lineSpacing
        self.letterSpacing = letterSpacing
        self.customFontName = customFontName
    }
}

// MARK: - View Modifiers para aplicar estilos de texto

/// Modificador para aplicar estilo de texto
public struct TextStyleModifier: ViewModifier {
    let style: TextStyleConfiguration
    let color: Color?
    let alignment: TextAlignment
    
    public init(
        style: TextStyleConfiguration, 
        color: Color? = nil, 
        alignment: TextAlignment = .leading
    ) {
        self.style = style
        self.color = color
        self.alignment = alignment
    }
    
    public func body(content: Content) -> some View {
        content
            .font(fontForStyle(style))
            .lineSpacing(style.size * (style.lineSpacing - 1))
            .tracking(style.letterSpacing)
            .if(color != nil) { view in
                view.foregroundColor(color)
            }
            .multilineTextAlignment(alignment)
    }
    
    private func fontForStyle(_ style: TextStyleConfiguration) -> Font {
        if let customFontName = style.customFontName {
            return .custom(customFontName, size: style.size)
        } else {
            return .system(size: style.size, weight: style.weight)
        }
    }
}

// MARK: - Font Debugging Helper

public struct FontDebugger {
    /// Lista todas as fontes disponíveis no sistema (para debugging)
    public static func listAllFonts() {
        for familyName in UIFont.familyNames.sorted() {
            Logger.shared.debug("Family: \(familyName)", context: "FontDebugger")
            for fontName in UIFont.fontNames(forFamilyName: familyName) {
                Logger.shared.debug("  Font: \(fontName)", context: "FontDebugger")
            }
        }
    }
    
    /// Verifica se uma fonte específica está disponível
    public static func isFontAvailable(_ fontName: String) -> Bool {
        return UIFont(name: fontName, size: 12) != nil
    }
    
    /// Lista fontes que contêm um termo específico (ex: "Futura")
    public static func findFonts(containing term: String) -> [String] {
        var matchingFonts: [String] = []
        for familyName in UIFont.familyNames {
            if familyName.lowercased().contains(term.lowercased()) {
                matchingFonts.append(contentsOf: UIFont.fontNames(forFamilyName: familyName))
            } else {
                for fontName in UIFont.fontNames(forFamilyName: familyName) {
                    if fontName.lowercased().contains(term.lowercased()) {
                        matchingFonts.append(fontName)
                    }
                }
            }
        }
        return matchingFonts
    }
}

// MARK: - Extensions

public extension View {
    /// Aplica um estilo de texto predefinido
    func textStyle(
        _ style: TextStyleConfiguration,
        color: Color? = nil,
        alignment: TextAlignment = .leading
    ) -> some View {
        self.modifier(TextStyleModifier(style: style, color: color, alignment: alignment))
    }
    
    /// Modificador condicional
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Extensões específicas para Text

public extension Text {
    // MARK: - Display Styles
    
    /// Display Extra Large - Para hero sections (64pt)
    func displayXLarge(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.displayXLarge, color: color, alignment: alignment)
    }
    
    /// Display Extra Large Futura - Para hero sections com fonte customizada (64pt, Futura PT Bold)
    func displayXLargeFutura(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.displayXLargeFutura, color: color, alignment: alignment)
    }
    
    /// Display Large - Para títulos de destaque (56pt)
    func displayLarge(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.displayLarge, color: color, alignment: alignment)
    }
    
    /// Display - Para hero sections e banners (48pt)
    func display(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.display, color: color, alignment: alignment)
    }
    
    // MARK: - Heading Hierarchy
    
    /// H1 - Títulos principais de tela (40pt)
    func h1(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.h1, color: color, alignment: alignment)
    }
    
    /// H2 - Títulos secundários (32pt)
    func h2(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.h2, color: color, alignment: alignment)
    }
    
    /// H3 - Títulos de seção (28pt)
    func h3(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.h3, color: color, alignment: alignment)
    }
    
    /// H4 - Subtítulos (24pt)
    func h4(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.h4, color: color, alignment: alignment)
    }
    
    /// H5 - Títulos pequenos (22pt)
    func h5(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.h5, color: color, alignment: alignment)
    }
    
    /// App Title Futura - Título do app com fonte Futura e espaçamento de 10% (24pt)
    func appTitleFutura(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.appTitleFutura, color: color, alignment: alignment)
    }
    
    /// Subtitle Large - Subtítulos grandes (20pt)
    func subtitleLarge(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.subtitleLarge, color: color, alignment: alignment)
    }
    
    /// Subtitle Large Semibold - Subtítulos grandes (20pt)
    func subtitleLargeSemiBold(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.subtitleLargeSemiBold, color: color, alignment: alignment)
    }
    
    /// Subtitle Large XXWide Semibold - Subtítulos grandes (20pt)
    func subtitleLargeXXWideSemiBold(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.subtitleLargeXXWideSemiBold, color: color, alignment: alignment)
    }
    
    /// Subtitle - Subtítulos padrão (18pt)
    func subtitle(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.subtitle, color: color, alignment: alignment)
    }
    
    // MARK: - Body Text
    
    /// Body Large - Texto de corpo grande (20pt)
    func bodyLarge(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.bodyLarge, color: color, alignment: alignment)
    }
    
    /// Body Large - Texto de corpo grande (18pt)
    func bodyMedium(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.bodyMedium, color: color, alignment: alignment)
    }
    
    /// Body Regular - Texto de corpo padrão (16pt)
    func bodyRegular(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.bodyRegular, color: color, alignment: alignment)
    }
    
    /// Body Emphasized - Texto de corpo em destaque (16pt)
    func bodyEmphasized(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.bodyEmphasized, color: color, alignment: alignment)
    }
    
    /// Body Large Emphasized - Texto de corpo em destaque (16pt)
    func bodyLargeEmphasized(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.bodyLargeEmphasized, color: color, alignment: alignment)
    }
    
    /// Body Bold - Texto de corpo em negrito (16pt)
    func bodyBold(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.bodyBold, color: color, alignment: alignment)
    }
    
    // MARK: - Supporting Text
    
    /// Caption Large - Legendas grandes (14pt)
    func captionLarge(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.captionLarge, color: color, alignment: alignment)
    }
    
    /// Caption - Legendas e informações secundárias (14pt)
    func caption(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.caption, color: color, alignment: alignment)
    }

    /// Caption Extra Bold - Texto compacto em negrito para títulos de cards (12pt)
    func captionExtraBold(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.captionExtraBold, color: color, alignment: alignment)
    }

    /// Hashtag - Hashtags e subtítulos secundários (11pt)
    func hashtag(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.hashtag, color: color, alignment: alignment)
    }
    
    /// Hashtag Light- Hashtags e subtítulos secundários (11pt)
    func hashtagLight(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.hashtagLight, color: color, alignment: alignment)
    }
    
    /// Footnote - Texto muito pequeno (12pt)
    func footnote(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.footnote, color: color, alignment: alignment)
    }
    
    /// Footnote Emphasized - Footnote em destaque (12pt)
    func footnoteEmphasized(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.footnoteEmphasized, color: color, alignment: alignment)
    }
    
    /// Footnote Light - Texto muito pequeno (12pt)
    func footnoteLight (color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.footnoteLight, color: color, alignment: alignment)
    }
    
    /// Micro - Texto mínimo (10pt)
    func micro(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.micro, color: color, alignment: alignment)
    }

    /// Micro Emphasized - Texto mínimo em destaque (10pt)
    func microEmphasized(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.microEmphasized, color: color, alignment: alignment)
    }

    /// Micro Light - Texto mínimo (10pt)
    func microLight(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.microLight, color: color, alignment: alignment)
    }

    /// Nano Light - Texto minúsculo (9pt)
    func nanoLight(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.nanoLight, color: color, alignment: alignment)
    }


    // MARK: - Interactive Elements
    
    /// Button Extra Large - Botões de destaque (20pt)
    func buttonXLarge(color: Color? = nil, alignment: TextAlignment = .center) -> some View {
        self.textStyle(Typography.TextStyle.buttonXLarge, color: color, alignment: alignment)
    }
    
    /// Button Large - Botões grandes (18pt)
    func buttonLarge(color: Color? = nil, alignment: TextAlignment = .center) -> some View {
        self.textStyle(Typography.TextStyle.buttonLarge, color: color, alignment: alignment)
    }
    
    /// Button Medium - Botões médios (16pt)
    func buttonMedium(color: Color? = nil, alignment: TextAlignment = .center) -> some View {
        self.textStyle(Typography.TextStyle.buttonMedium, color: color, alignment: alignment)
    }
    
    /// Button Small - Botões pequenos (14pt)
    func buttonSmall(color: Color? = nil, alignment: TextAlignment = .center) -> some View {
        self.textStyle(Typography.TextStyle.buttonSmall, color: color, alignment: alignment)
    }
    
    /// Label - Labels de interface (14pt)
    func label(color: Color? = nil, alignment: TextAlignment = .leading) -> some View {
        self.textStyle(Typography.TextStyle.label, color: color, alignment: alignment)
    }
    
    /// Tab Bar - Texto de tab bar (10pt)
    func tabBar(color: Color? = nil, alignment: TextAlignment = .center) -> some View {
        self.textStyle(Typography.TextStyle.tabBar, color: color, alignment: alignment)
    }
}

// MARK: - Exemplos de Uso

/*
 
 // DISPLAY STYLES - Para hero sections e destaque máximo
 Text("Welcome to Bandz").displayXLarge()           // 64pt, system bold, tight spacing
 Text("Welcome to Bandz").displayXLargeFutura()     // 64pt, Futura PT Bold, tight spacing
 Text("Discover Music").display()                   // 48pt, bold, compact spacing
 
 // HEADING HIERARCHY - Para estrutura de conteúdo
 Text("Título Principal").h1()                      // 40pt, bold
 Text("Título Secundário").h2()                     // 32pt, bold  
 Text("Título de Seção").h3()                       // 28pt, semibold
 Text("Subtítulo").h4()                             // 24pt, semibold
 Text("Título Pequeno").h5()                        // 22pt, medium
 Text("Subtítulo Grande").subtitleLarge()           // 20pt, medium
 Text("Subtítulo Padrão").subtitle()                // 18pt, medium
 
 // BODY TEXT - Para conteúdo principal
 Text("Texto de corpo grande").bodyLarge()          // 18pt, regular
 Text("Texto de corpo padrão").bodyRegular()        // 16pt, regular
 Text("Texto em destaque").bodyEmphasized()         // 16pt, medium
 Text("Texto em negrito").bodyBold()                // 16pt, bold
 
 // SUPPORTING TEXT - Para informações secundárias
 Text("Legenda grande").captionLarge()              // 14pt, regular
 Text("Legenda padrão").caption()                   // 14pt, medium
 Text("Nota de rodapé").footnote()                  // 12pt, regular
 Text("Nota destacada").footnoteEmphasized()        // 12pt, medium
 Text("Texto micro").micro()                        // 10pt, regular
 
 // INTERACTIVE ELEMENTS - Para botões e controles
 Text("Button XL").buttonXLarge()                   // 20pt, semibold
 Text("Button Large").buttonLarge()                 // 18pt, semibold
 Text("Button Medium").buttonMedium()               // 16pt, semibold
 Text("Button Small").buttonSmall()                 // 14pt, medium
 Text("Label").label()                              // 14pt, medium
 Text("Tab").tabBar()                               // 10pt, medium
 
 // Com cores personalizadas e alinhamento
 Text("Texto com cor").bodyRegular(color: .blue)
 Text("Texto centralizado").h1(alignment: .center)
 Text("Display com cor").display(color: Color("Primary"), alignment: .center)
 
 // Aplicando diretamente o modificador para estilos customizados
 Text("Estilo personalizado")
     .textStyle(Typography.TextStyle.display, color: .red, alignment: .trailing)
 
 // USAGE GUIDELINES:
 // - Display: Hero sections, splash screens, primary CTAs
 // - H1-H5: Hierarchical content structure
 // - Body: Main content, descriptions, paragraphs  
 // - Supporting: Captions, footnotes, secondary info
 // - Interactive: Buttons, tabs, labels, controls
 
*/
