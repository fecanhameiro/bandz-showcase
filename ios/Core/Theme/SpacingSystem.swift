import SwiftUI

/// Sistema de espaçamento para padronização de SpacingSystem e padding em toda a aplicação
///
/// Este sistema define valores padronizados para margins, paddings e SpacingSystems,
/// garantindo consistência visual em todo o aplicativo.
public enum SpacingSystem {
    /// Espaçamentos padrão da aplicação
    public struct Size {
        /// 0 points
        public static let none: CGFloat = 0
        
        /// 2 points - Espaçamento mínimo para elementos muito próximos
        public static let xxxs: CGFloat = 2
        
        /// 4 points - Espaçamento muito pequeno
        public static let xxs: CGFloat = 4
        
        /// 8 points - Espaçamento pequeno
        public static let xs: CGFloat = 8
        
        /// 12 points - Espaçamento menor que médio
        public static let sm: CGFloat = 12
        
        /// 16 points - Espaçamento médio (utilizado como padrão)
        public static let md: CGFloat = 16
        
        /// 24 points - Espaçamento médio-grande
        public static let lg: CGFloat = 24
        
        /// 32 points - Espaçamento grande
        public static let xl: CGFloat = 32
        
        /// 40 points - Espaçamento muito grande
        public static let xxl: CGFloat = 40
        
        /// 48 points - Espaçamento extra grande
        public static let xxxl: CGFloat = 48
        
        /// 64 points - Espaçamento máximo padrão
        public static let max: CGFloat = 64
    }
    
    /// Insets (padding) comuns usados na aplicação
    public struct Inset {
        /// Inset padrão para Views (16)
        public static let standard: CGFloat = Size.md
        
        /// Inset para páginas e contêineres principais (24)
        public static let page: CGFloat = Size.lg
        
        /// Inset para elementos pequenos como cards (12)
        public static let card: CGFloat = Size.sm
        
        /// Inset para elementos compactos como botões (8)
        public static let compact: CGFloat = Size.xs
        
        /// Inset nulo (0)
        public static let none: CGFloat = Size.none
        
        /// Estrutura para padronização de insets horizontais e verticais
        public struct Horizontal {
            /// Padrão horizontal (16)
            public static let standard: CGFloat = Size.md
            
            /// Página horizontal (24)
            public static let page: CGFloat = Size.lg
            
            /// Estreito horizontal (8)
            public static let narrow: CGFloat = Size.xs
            
            /// Amplo horizontal (32)
            public static let wide: CGFloat = Size.xl
        }
        
        /// Estrutura para padronização de insets verticais
        public struct Vertical {
            /// Padrão vertical (16)
            public static let standard: CGFloat = Size.md
            
            /// Compacto vertical (8)
            public static let compact: CGFloat = Size.xs
            
            /// Amplo vertical (24)
            public static let wide: CGFloat = Size.lg
            
            /// Ampliado vertical (32)
            public static let expanded: CGFloat = Size.xl
            /// Ampliado vertical (40)
            public static let expandedXL: CGFloat = Size.xxl
        }
    }
    
    /// Espaçamentos entre itens em stacks
    public struct Stack {
        /// Espaçamento mínimo (2)
        public static let minimal: CGFloat = Size.xxxs
        
        /// Espaçamento extra pequeno (4)
        public static let extraSmall: CGFloat = Size.xxs
        
        /// Espaçamento pequeno (8)
        public static let small: CGFloat = Size.xs
        
        /// Espaçamento médio (16) - Padrão
        public static let medium: CGFloat = Size.md
        
        /// Espaçamento grande (24)
        public static let large: CGFloat = Size.lg
        
        /// Espaçamento extra grande (32)
        public static let extraLarge: CGFloat = Size.xl
    }
    
    /// Alturas padrão para elementos comuns
    public struct Height {
        /// Altura padrão para botões grandes (56)
        public static let largeButton: CGFloat = 56
        
        /// Altura padrão para botões médios (48)
        public static let mediumButton: CGFloat = 48
        
        /// Altura padrão para botões pequenos (36)
        public static let smallButton: CGFloat = 36
        
        /// Altura padrão para campos de entrada (52)
        public static let inputField: CGFloat = 52
        
        /// Altura para elementos pequenos de UI como badges (24)
        public static let badge: CGFloat = 24
        
        /// Altura para barras de topo e navegação (44)
        public static let navigationBar: CGFloat = 44
        
        /// Altura para linhas de divider (1)
        public static let divider: CGFloat = 1
        
        /// Icones do evento 18
        public static let eventIcon: CGFloat = 18
        
        /// Icones do evento small 14
        public static let eventIconSmall: CGFloat = 14
    }
    
    /// Tamanhos de corner radius padronizados
    public struct CornerRadius {
        /// Cantos pequenos (4)
        public static let small: CGFloat = 4
        
        /// Cantos médios (8)
        public static let medium: CGFloat = 8
        
        /// Cantos padrão (12) - usado na maioria dos elementos
        public static let standard: CGFloat = 12
        
        /// Cantos grandes (16)
        public static let large: CGFloat = 16
        
        /// Cantos extra grandes (24)
        public static let extraLarge: CGFloat = 24
        
        /// Cantos redondos - metade da altura (para círculos)
        public static func rounded(_ height: CGFloat) -> CGFloat {
            return height / 2
        }
    }
}

// MARK: - View Modifiers para facilitar o uso do sistema de espaçamento

/// Modificador para aplicar padding horizontal padrão
struct HorizontalPaddingModifier: ViewModifier {
    let padding: CGFloat
    
    init(_ style: PaddingStyle = .standard) {
        switch style {
        case .none:
            self.padding = SpacingSystem.Inset.none
        case .compact:
            self.padding = SpacingSystem.Inset.Horizontal.narrow
        case .standard:
            self.padding = SpacingSystem.Inset.Horizontal.standard
        case .wide:
            self.padding = SpacingSystem.Inset.Horizontal.page
        case .extraWide:
            self.padding = SpacingSystem.Inset.Horizontal.wide
        case .custom(let value):
            self.padding = value
        }
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, padding)
    }
}

/// Modificador para aplicar padding vertical padrão
struct VerticalPaddingModifier: ViewModifier {
    let padding: CGFloat
    
    init(_ style: PaddingStyle = .standard) {
        switch style {
        case .none:
            self.padding = SpacingSystem.Inset.none
        case .compact:
            self.padding = SpacingSystem.Inset.Vertical.compact
        case .standard:
            self.padding = SpacingSystem.Inset.Vertical.standard
        case .wide:
            self.padding = SpacingSystem.Inset.Vertical.wide
        case .extraWide:
            self.padding = SpacingSystem.Inset.Vertical.expanded
        case .custom(let value):
            self.padding = value
        }
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.vertical, padding)
    }
}

/// Modificador para aplicar padding em todos os lados
struct StandardPaddingModifier: ViewModifier {
    let padding: CGFloat
    
    init(_ style: PaddingStyle = .standard) {
        switch style {
        case .none:
            self.padding = SpacingSystem.Inset.none
        case .compact:
            self.padding = SpacingSystem.Inset.compact
        case .standard:
            self.padding = SpacingSystem.Inset.standard
        case .wide:
            self.padding = SpacingSystem.Inset.page
        case .extraWide:
            self.padding = SpacingSystem.Size.xl
        case .custom(let value):
            self.padding = value
        }
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
    }
}

/// Estilos de padding disponíveis
public enum PaddingStyle {
    case none
    case compact
    case standard
    case wide
    case extraWide
    case custom(CGFloat)
}

/// Estilos de SpacingSystem para stacks
public enum StackSpacingSystemStyle {
    case none
    case minimal
    case extraSmall
    case small
    case medium
    case large
    case extraLarge
    case custom(CGFloat)
    
    var value: CGFloat {
        switch self {
        case .none:
            return SpacingSystem.Size.none
        case .minimal:
            return SpacingSystem.Stack.minimal
        case .extraSmall:
            return SpacingSystem.Stack.extraSmall
        case .small:
            return SpacingSystem.Stack.small
        case .medium:
            return SpacingSystem.Stack.medium
        case .large:
            return SpacingSystem.Stack.large
        case .extraLarge:
            return SpacingSystem.Stack.extraLarge
        case .custom(let value):
            return value
        }
    }
}

// MARK: - Extensões para View

public extension View {
    /// Aplica padding horizontal padronizado
    func horizontalPadding(_ style: PaddingStyle = .standard) -> some View {
        self.modifier(HorizontalPaddingModifier(style))
    }
    
    /// Aplica padding vertical padronizado
    func verticalPadding(_ style: PaddingStyle = .standard) -> some View {
        self.modifier(VerticalPaddingModifier(style))
    }
    
    /// Aplica padding padronizado em todos os lados
    func standardPadding(_ style: PaddingStyle = .standard) -> some View {
        self.modifier(StandardPaddingModifier(style))
    }
    
    /// Aplica corner radius padronizado
    func standardCornerRadius(_ style: CornerRadiusStyle = .standard) -> some View {
        self.cornerRadius(style.value)
    }
    
    /// Aplica margin padrão (padding externos)
    func margin(_ edges: Edge.Set = .all, _ style: PaddingStyle = .standard) -> some View {
        let value: CGFloat
        
        switch style {
        case .none:
            value = SpacingSystem.Size.none
        case .compact:
            value = SpacingSystem.Size.xs
        case .standard:
            value = SpacingSystem.Size.md
        case .wide:
            value = SpacingSystem.Size.lg
        case .extraWide:
            value = SpacingSystem.Size.xl
        case .custom(let customValue):
            value = customValue
        }
        
        return self.padding(edges, value)
    }
}

/// Estilos de corner radius
public enum CornerRadiusStyle {
    case small
    case medium
    case standard
    case large
    case extraLarge
    case rounded(CGFloat)
    case custom(CGFloat)
    
    var value: CGFloat {
        switch self {
        case .small:
            return SpacingSystem.CornerRadius.small
        case .medium:
            return SpacingSystem.CornerRadius.medium
        case .standard:
            return SpacingSystem.CornerRadius.standard
        case .large:
            return SpacingSystem.CornerRadius.large
        case .extraLarge:
            return SpacingSystem.CornerRadius.extraLarge
        case .rounded(let height):
            return SpacingSystem.CornerRadius.rounded(height)
        case .custom(let value):
            return value
        }
    }
}

// MARK: - Extensões para VStack e HStack com SpacingSystem padronizado

public extension View {
    /// Cria um VStack com SpacingSystem padronizado
    func vStack(alignment: HorizontalAlignment = .center, 
                spacing: StackSpacingSystemStyle = .medium, 
                @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: alignment, spacing: spacing.value) {
            self
            content()
        }
    }
    
    /// Cria um HStack com SpacingSystem padronizado
    func hStack(alignment: VerticalAlignment = .center, 
                spacing: StackSpacingSystemStyle = .medium, 
                @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: alignment, spacing: spacing.value) {
            self
            content()
        }
    }
}

// MARK: - Extensões para facilitar a criação de Stacks com SpacingSystem padronizado

/// VStack com SpacingSystem padronizado
public struct StandardVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let content: Content
    
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: StackSpacingSystemStyle = .medium,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing.value
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
    }
}

/// HStack com SpacingSystem padronizado
public struct StandardHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat
    let content: Content
    
    public init(
        alignment: VerticalAlignment = .center,
        spacing: StackSpacingSystemStyle = .medium,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing.value
        self.content = content()
    }
    
    public var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            content
        }
    }
}

// MARK: - Exemplos de Uso

/*
 
 // Padding padrão em todos os lados
 Text("Exemplo")
     .standardPadding()
 
 // Padding horizontal mais amplo
 Text("Exemplo")
     .horizontalPadding(.wide)
 
 // Padding vertical compacto
 Text("Exemplo")
     .verticalPadding(.compact)
 
 // Cantos arredondados padrão
 Rectangle()
     .standardCornerRadius()
 
 // Margin padrão
 Text("Exemplo")
     .margin()
 
 // Apenas margin superior
 Text("Exemplo")
     .margin(.top, .large)
 
 // VStack com espaçamento padrão
 StandardVStack {
     Text("Item 1")
     Text("Item 2")
     Text("Item 3")
 }
 
 // HStack com espaçamento pequeno
 StandardHStack(spacing: .small) {
     Text("Item 1")
     Text("Item 2")
     Text("Item 3")
 }
 
 // Combinar com view existente
 Text("Item inicial")
     .hStack(spacing: .large) {
         Text("Item adicionado")
     }
 
*/
