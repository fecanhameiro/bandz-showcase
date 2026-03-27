import SwiftUI

/// Sistema de elevação para padronização de sombras, blur e efeitos de profundidade
///
/// Este sistema define valores padronizados para criar uma hierarquia visual
/// consistente em toda a aplicação através de sombras e efeitos.
public enum ElevationSystem {
    /// Níveis de elevação para diferentes contextos de UI
    public enum Level: Int, CaseIterable {
        /// Sem elevação (level 0)
        case none = 0
        
        /// Elevação mínima, para elementos sutis (level 1)
        case subtle = 1
        
        /// Elevação moderada, para cards e botões (level 2)
        case medium = 2
        
        /// Elevação alta, para elementos flutuantes (level 3)
        case high = 3
        
        /// Elevação máxima, para modais e popovers (level 4)
        case highest = 4
        
        /// Configuração de sombra para este nível
        var shadow: Shadow {
            switch self {
            case .none:
                return Shadow(radius: 0, y: 0, opacity: 0)
            case .subtle:
                return Shadow(radius: 2, y: 1, opacity: 0.1)
            case .medium:
                return Shadow(radius: 4, y: 2, opacity: 0.15)
            case .high:
                return Shadow(radius: 8, y: 4, opacity: 0.2)
            case .highest:
                return Shadow(radius: 16, y: 8, opacity: 0.25)
            }
        }
        
        /// Blur para este nível
        var blur: Blur {
            switch self {
            case .none:
                return Blur(radius: 0, material: .ultraThinMaterial)
            case .subtle:
                return Blur(radius: 2, material: .ultraThinMaterial)
            case .medium:
                return Blur(radius: 5, material: .thinMaterial)
            case .high:
                return Blur(radius: 10, material: .regularMaterial)
            case .highest:
                return Blur(radius: 20, material: .thickMaterial)
            }
        }
        
        /// Escala para este nível (usado em hover ou press states)
        var scaleEffect: CGFloat {
            switch self {
            case .none:
                return 1.0
            case .subtle:
                return 1.02
            case .medium:
                return 1.04
            case .high:
                return 1.06
            case .highest:
                return 1.08
            }
        }
    }
    
    /// Configuração de sombra
    public struct Shadow {
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        let color: Color
        let opacity: Double
        
        public init(
            radius: CGFloat,
            x: CGFloat = 0,
            y: CGFloat,
            color: Color = .black,
            opacity: Double
        ) {
            self.radius = radius
            self.x = x
            self.y = y
            self.color = color
            self.opacity = opacity
        }
    }
    
    /// Configuração de blur
    public struct Blur {
        let radius: CGFloat
        let material: Material
        
        public init(
            radius: CGFloat,
            material: Material
        ) {
            self.radius = radius
            self.material = material
        }
    }
    
    /// Estilos específicos de sombra
    public struct ShadowStyle {
        /// Sombra para cards
        public static let card = Level.medium.shadow
        
        /// Sombra para botões
        public static let button = Level.subtle.shadow
        
        /// Sombra para elementos flutuantes
        public static let floating = Level.high.shadow
        
        /// Sombra para modais
        public static let modal = Level.highest.shadow
        
        /// Sombra interna para campos de texto
        public static let innerField = Shadow(radius: 1, y: 1, opacity: 0.1)
        
        /// Sem sombra
        public static let none = Level.none.shadow
    }
    
    /// Estilos específicos de blur
    public struct BlurStyle {
        /// Blur sutil para fundos
        public static let subtle = Level.subtle.blur
        
        /// Blur médio para elementos de sobreposição
        public static let medium = Level.medium.blur
        
        /// Blur intenso para modais
        public static let intense = Level.highest.blur
        
        /// Sem blur
        public static let none = Level.none.blur
    }
}

// MARK: - View Modifiers para aplicar elevação

/// Modificador para aplicar efeito de elevação com sombra
public struct ElevationModifier: ViewModifier {
    let level: ElevationSystem.Level
    
    public init(_ level: ElevationSystem.Level) {
        self.level = level
    }
    
    public func body(content: Content) -> some View {
        let shadow = level.shadow
        
        return content
            .shadow(
                color: shadow.color.opacity(shadow.opacity),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

/// Modificador para aplicar sombra personalizada
public struct ShadowStyleModifier: ViewModifier {
    let shadow: ElevationSystem.Shadow
    
    public init(_ shadow: ElevationSystem.Shadow) {
        self.shadow = shadow
    }
    
    public func body(content: Content) -> some View {
        content
            .shadow(
                color: shadow.color.opacity(shadow.opacity),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

/// Modificador para aplicar blur
public struct BlurStyleModifier: ViewModifier {
    let blur: ElevationSystem.Blur
    
    public init(_ blur: ElevationSystem.Blur) {
        self.blur = blur
    }
    
    public func body(content: Content) -> some View {
        content.blur(radius: blur.radius)
    }
}

/// Modificador para aplicar material blur com fundo translúcido
public struct MaterialBlurModifier: ViewModifier {
    let blur: ElevationSystem.Blur
    
    public init(_ blur: ElevationSystem.Blur) {
        self.blur = blur
    }
    
    public func body(content: Content) -> some View {
        content
            .background(blur.material)
    }
}

/// Modificador para aplicar elevação com efeito pressed
public struct PressableElevationModifier: ViewModifier {
    let restLevel: ElevationSystem.Level
    let pressedLevel: ElevationSystem.Level
    @State private var isPressed: Bool = false
    
    public init(
        rest: ElevationSystem.Level = .subtle,
        pressed: ElevationSystem.Level = .medium
    ) {
        self.restLevel = rest
        self.pressedLevel = pressed
    }
    
    public func body(content: Content) -> some View {
        content
            .elevation(isPressed ? pressedLevel : restLevel)
            .scaleEffect(isPressed ? pressedLevel.scaleEffect : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

// MARK: - Extensions para View

public extension View {
    /// Aplica elevação padronizada
    func elevation(_ level: ElevationSystem.Level) -> some View {
        self.modifier(ElevationModifier(level))
    }
    
    /// Aplica estilo de sombra personalizado
    func shadowStyle(_ style: ElevationSystem.Shadow) -> some View {
        self.modifier(ShadowStyleModifier(style))
    }
    
    /// Aplica estilo de blur
    func blurStyle(_ style: ElevationSystem.Blur) -> some View {
        self.modifier(BlurStyleModifier(style))
    }
    
    /// Aplica material blur de fundo
    func materialBlur(_ style: ElevationSystem.Blur) -> some View {
        self.modifier(MaterialBlurModifier(style))
    }
    
    /// Aplica elevação com efeito de pressionar
    func pressableElevation(
        rest: ElevationSystem.Level = .subtle,
        pressed: ElevationSystem.Level = .medium
    ) -> some View {
        self.modifier(PressableElevationModifier(rest: rest, pressed: pressed))
    }
    
    /// Aplica estilo de card com sombra adequada
    func cardStyle(cornerRadius: CGFloat = SpacingSystem.CornerRadius.standard) -> some View {
        self
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadowStyle(ElevationSystem.ShadowStyle.card)
    }
    
    /// Aplica estilo de modal com sombra intensa
    func modalStyle(cornerRadius: CGFloat = SpacingSystem.CornerRadius.large) -> some View {
        self
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadowStyle(ElevationSystem.ShadowStyle.modal)
    }
}

// MARK: - Componentes de elevação pré-configurados

/// Contêiner com efeito de vidro (glassmorphism)
public struct GlassContainer<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content
    
    public init(
        cornerRadius: CGFloat = SpacingSystem.CornerRadius.standard,
        padding: CGFloat = SpacingSystem.Inset.standard,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .elevation(.subtle)
    }
}

// MARK: - Exemplos de Uso

/*
 
 // Elevação básica
 Text("Card com elevação média")
     .padding()
     .background(Color.white)
     .cornerRadius(12)
     .elevation(.medium)
 
 // Cartão pré-configurado
 ElevatedCard {
     VStack(alignment: .leading) {
         Text("Título do Card")
             .font(.headline)
         
         Text("Descrição ou conteúdo do card com elevação incorporada...")
             .font(.body)
     }
     .padding()
 }
 
 // Estilo de card
 VStack(alignment: .leading) {
     Text("Card estilizado")
         .font(.headline)
     
     Text("Conteúdo...")
 }
 .padding()
 .cardStyle()
 
 // Contêiner com efeito de vidro
 ZStack {
     // Fundo colorido ou imagem
     Image("background")
         .resizable()
         .edgesIgnoringSafeArea(.all)
     
     GlassContainer {
         Text("Conteúdo sobre vidro")
     }
     .padding()
 }
 
 // Componente com elevação responsiva a pressionar
 Text("Pressione-me")
     .padding()
     .background(Color.white)
     .cornerRadius(8)
     .pressableElevation(rest: .subtle, pressed: .high)
 
*/
