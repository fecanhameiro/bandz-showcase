import SwiftUI

/// Sistema de layout para padronização em toda a aplicação
///
/// Este sistema oferece abstrações para gerenciar layouts responsivos,
/// grids, safe areas e outros aspectos de layout no aplicativo.
public enum LayoutSystem {
    /// Tamanhos de tela para ajustes responsivos
    public enum ScreenSize {
        case small      // iPhone SE, 5, 5S, 5C (4" e menores)
        case medium     // iPhone 6, 7, 8, X, XS, 11 Pro, 12 mini (4.7"-5.8")
        case large      // iPhone 6+, 7+, 8+, XR, XS Max, 11, 11 Pro Max (6.1"-6.7")
        case extraLarge // iPad
        
        /// Obtém o tamanho de tela atual com base no tamanho da tela
        public static var current: ScreenSize {
            let width = UIScreen.main.bounds.width
            let height = UIScreen.main.bounds.height
            let maxDimension = max(width, height)
            
            switch maxDimension {
            case 0..<568:
                return .small
            case 568..<812:
                return .medium
            case 812..<1024:
                return .large
            default:
                return .extraLarge
            }
        }
    }
    
    /// Definições de grid para layout consistente
    public struct Grid {
        /// Número de colunas para diferentes tamanhos de tela
        public static let columns = [
            ScreenSize.small: 4,
            ScreenSize.medium: 4,
            ScreenSize.large: 4,
            ScreenSize.extraLarge: 8
        ]
        
        /// Espaçamento entre colunas para diferentes tamanhos de tela
        public static let columnSpacingSystem: [ScreenSize: CGFloat] = [
            .small: SpacingSystem.Size.xs,
            .medium: SpacingSystem.Size.md,
            .large: SpacingSystem.Size.md,
            .extraLarge: SpacingSystem.Size.lg
        ]
        
        /// Espaçamento entre linhas para diferentes tamanhos de tela
        public static let rowSpacingSystem: [ScreenSize: CGFloat] = [
            .small: SpacingSystem.Size.xs,
            .medium: SpacingSystem.Size.md,
            .large: SpacingSystem.Size.md,
            .extraLarge: SpacingSystem.Size.lg
        ]
        
        /// Retorna um GridItem array para uso com LazyVGrid ou LazyHGrid
        public static func gridItems(for screenSize: ScreenSize = ScreenSize.current) -> [GridItem] {
            let columns = self.columns[screenSize] ?? 4
            _ = self.columnSpacingSystem[screenSize] ?? SpacingSystem.Size.md

            return Array(repeating: GridItem(.flexible(minimum: 80)), count: columns)
        }
        
        /// Cria um grid de dois itens por linha com espaçamento personalizado
        public static func twoColumnGrid(spacing: CGFloat = SpacingSystem.Size.md) -> [GridItem] {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
        
        /// Cria um grid de três itens por linha com espaçamento personalizado
        public static func threeColumnGrid(spacing: CGFloat = SpacingSystem.Size.md) -> [GridItem] {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    /// Constantes para gerenciamento de proporções
    public struct AspectRatio {
        /// Proporção quadrada (1:1)
        public static let square: CGFloat = 1
        
        /// Proporção 4:3
        public static let standard: CGFloat = 4/3
        
        /// Proporção 16:9
        public static let widescreen: CGFloat = 16/9
        
        /// Proporção 21:9 (ultrawide)
        public static let ultrawide: CGFloat = 21/9
        
        /// Proporção 2:3 (retrato)
        public static let portrait: CGFloat = 2/3
        
        /// Proporção cartão de crédito
        public static let card: CGFloat = 1.586
    }
    
    /// Valores de Z-index para gerenciar camadas de elementos
    public struct ZIndex {
        /// Elementos de fundo (0)
        public static let background: Double = 0
        
        /// Elementos de conteúdo (10)
        public static let content: Double = 10
        
        /// Elementos em destaque ou que se sobrepõem (20)
        public static let featured: Double = 20
        
        /// Elementos de overlay (50)
        public static let overlay: Double = 50
        
        /// Elementos de controle que flutuam na interface (100)
        public static let control: Double = 100
        
        /// Elementos de notificação ou alerta (200)
        public static let notification: Double = 200
        
        /// Elementos modais que cobrem a interface (500)
        public static let modal: Double = 500
        
        /// Elementos de máxima prioridade visual (1000)
        public static let maximum: Double = 1000
    }
    
    /// Constantes para tamanhos de elementos comuns
    public struct ElementSize {
        /// Altura padrão para barras de navegação
        public static let navigationBar: CGFloat = 44
        
        /// Altura padrão para barras de tab
        public static let tabBar: CGFloat = 49
        
        /// Altura de um item minimo de menu 
        public static let menuItem: CGFloat = 44
        
        /// Tamanho de ícone pequeno
        public static let smallIcon: CGFloat = 24
        
        /// Tamanho de ícone médio
        public static let mediumIcon: CGFloat = 32
        
        /// Tamanho de ícone grande
        public static let largeIcon: CGFloat = 44

        /// Tamanho de ícone decorativo para estados (error, empty, dialog)
        public static let stateIcon: CGFloat = 48

        /// Altura mínima recomendada para áreas tocáveis
        public static let touchTarget: CGFloat = 44
        
        /// Largura máxima para texto legível
        public static let readableWidth: CGFloat = 650
        
        /// Tamanho de avatar pequeno
        public static let smallAvatar: CGFloat = 32
        
        /// Tamanho de avatar médio
        public static let mediumAvatar: CGFloat = 48
        
        /// Tamanho de avatar grande
        public static let largeAvatar: CGFloat = 88
    }
    
    /// Acesso rápido aos insets de safe area do app
    public struct SafeArea {
        public static var insets: UIEdgeInsets { UIApplication.safeAreaInsets }
        public static var top: CGFloat { UIApplication.safeAreaTop }
        public static var bottom: CGFloat { UIApplication.safeAreaBottom }
        public static var left: CGFloat { UIApplication.safeAreaLeft }
        public static var right: CGFloat { UIApplication.safeAreaRight }
    }
    
    /// Constantes para tamanhos de elements adaptativos por tamanho de tela
    public struct AdaptiveSize {
        /// Retorna o padding horizontal adequado para cada tamanho de tela
        public static func horizontalPadding(for screenSize: ScreenSize = ScreenSize.current) -> CGFloat {
            switch screenSize {
            case .small:
                return SpacingSystem.Inset.Horizontal.standard
            case .medium:
                return SpacingSystem.Inset.Horizontal.page
            case .large:
                return SpacingSystem.Inset.Horizontal.page
            case .extraLarge:
                return SpacingSystem.Inset.Horizontal.wide
            }
        }
        
        /// Retorna a largura máxima para conteúdo baseado no tamanho da tela
        public static func contentMaxWidth(for screenSize: ScreenSize = ScreenSize.current) -> CGFloat? {
            switch screenSize {
            case .small, .medium, .large:
                return nil // Sem limite em dispositivos pequenos
            case .extraLarge:
                return 800 // Limitar em iPads e telas maiores
            }
        }
        
        /// Retorna a largura para card baseado no tamanho da tela
        public static func cardWidth(for screenSize: ScreenSize = ScreenSize.current) -> CGFloat {
            switch screenSize {
            case .small:
                return 140
            case .medium:
                return 160
            case .large:
                return 180
            case .extraLarge:
                return 220
            }
        }
    }
    
    /// Padrões de padding para diferentes tamanhos de tela
    public struct ScreenPadding {
        /// Padding para tela pequena
        public static let small = (
            horizontal: SpacingSystem.Inset.Horizontal.standard,
            vertical: SpacingSystem.Inset.Vertical.standard
        )
        
        /// Padding para tela média
        public static let medium = (
            horizontal: SpacingSystem.Inset.Horizontal.page,
            vertical: SpacingSystem.Inset.Vertical.standard
        )
        
        /// Padding para tela grande
        public static let large = (
            horizontal: SpacingSystem.Inset.Horizontal.wide,
            vertical: SpacingSystem.Inset.Vertical.wide
        )
        
        /// Obtém o padding adequado para o tamanho de tela atual
        public static func current() -> (horizontal: CGFloat, vertical: CGFloat) {
            switch ScreenSize.current {
            case .small:
                return small
            case .medium, .large:
                return medium
            case .extraLarge:
                return large
            }
        }
    }
}

// MARK: - Extensões para View

public extension View {
    /// Limita a largura para um valor confortável de leitura
    func readableWidth() -> some View {
        self.frame(maxWidth: LayoutSystem.ElementSize.readableWidth)
    }
    
    /// Garante tamanho mínimo para alvo de toque
    func touchTarget() -> some View {
        self.frame(minWidth: LayoutSystem.ElementSize.touchTarget, minHeight: LayoutSystem.ElementSize.touchTarget)
    }
    
    /// Aplica layout responsivo baseado no tamanho da tela
    func responsiveLayout() -> some View {
        let padding = LayoutSystem.ScreenPadding.current()
        
        return self
            .padding(.horizontal, padding.horizontal)
            .padding(.vertical, padding.vertical)
    }
    
    /// Aplica layout responsivo com largura máxima para telas grandes
    func responsiveContainerLayout(alignment: Alignment = .center) -> some View {
        let padding = LayoutSystem.ScreenPadding.current()
        let maxWidth = LayoutSystem.AdaptiveSize.contentMaxWidth()
        
        return self
            .padding(.horizontal, padding.horizontal)
            .padding(.vertical, padding.vertical)
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    /// Posiciona a view na camada z (z-index) especificada
    func zLayer(_ layer: Double) -> some View {
        self.zIndex(layer)
    }
    
    /// Aplica um layout de grid responsivo
    func responsiveGrid<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let columns = LayoutSystem.Grid.gridItems()
        let rowSpacing = LayoutSystem.Grid.rowSpacingSystem[LayoutSystem.ScreenSize.current] ?? SpacingSystem.Size.md
        
        return LazyVGrid(columns: columns, spacing: rowSpacing) {
            content()
        }
    }
    
    /// Aplica um grid de duas colunas
    func twoColumnGrid<Content: View>(
        spacing: CGFloat = SpacingSystem.Size.md,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        LazyVGrid(columns: LayoutSystem.Grid.twoColumnGrid(), spacing: spacing) {
            content()
        }
    }
    
    /// Aplica um grid de três colunas
    func threeColumnGrid<Content: View>(
        spacing: CGFloat = SpacingSystem.Size.md,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        LazyVGrid(columns: LayoutSystem.Grid.threeColumnGrid(), spacing: spacing) {
            content()
        }
    }
}

// MARK: - Layouts personalizados

/// Container com layout responsivo
public struct ResponsiveContainer<Content: View>: View {
    let alignment: Alignment
    let content: Content
    
    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }
    
    public var body: some View {
        content
            .responsiveContainerLayout(alignment: alignment)
    }
}

/// Layout de grade adaptativo
public struct AdaptiveGrid<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item) -> Content
    
    public init(
        items: [Item],
        spacing: CGFloat = SpacingSystem.Size.md,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        let rowSpacing = LayoutSystem.Grid.rowSpacingSystem[LayoutSystem.ScreenSize.current] ?? spacing
        
        LazyVGrid(
            columns: LayoutSystem.Grid.gridItems(),
            spacing: rowSpacing
        ) {
            ForEach(items) { item in
                content(item)
            }
        }
        .padding(.horizontal, LayoutSystem.AdaptiveSize.horizontalPadding())
    }
}

// MARK: - Exemplos de Uso

/*
 
 // Container responsivo básico
 ResponsiveContainer {
     Text("Conteúdo que se adapta a diferentes tamanhos de tela")
 }
 
 // Layout responsivo
 VStack {
     Text("Título da Seção")
     
     Image("banner")
         .resizable()
         .aspectRatio(LayoutSystem.AspectRatio.widescreen, contentMode: .fill)
 }
 .responsiveLayout()
 
 // Grid adaptativo
 ScrollView {
     responsiveGrid {
         ForEach(items) { item in
             ItemCard(item: item)
         }
     }
     .padding()
 }
 
 // Grid adaptativo com dados
 AdaptiveGrid(items: myItems) { item in
     ItemView(item: item)
 }
 
 // Grid de 2 colunas
 ScrollView {
     twoColumnGrid {
         ForEach(items) { item in
             ItemCard(item: item)
         }
     }
     .padding()
 }
 
 // Garantindo tamanho para alvo de toque
 Button(action: {}) {
     Image(systemName: "plus")
 }
 .touchTarget()
 
 // Camadas (z-index)
 ZStack {
     backgroundView
         .zLayer(LayoutSystem.ZIndex.background)
     
     contentView
         .zLayer(LayoutSystem.ZIndex.content)
     
     overlayView
         .zLayer(LayoutSystem.ZIndex.overlay)
 }
 
*/
