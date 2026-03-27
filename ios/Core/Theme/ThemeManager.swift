import SwiftUI
import Observation

/// Gerenciador de tema do aplicativo
/// Migrated to @Observable for iOS 17+ performance benefits.
@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    // MARK: - Observable Properties
    var colorScheme: ColorScheme?
    var currentTheme: AppTheme

    // MARK: - Private Properties
    @ObservationIgnored private let userDefaultsKey = "appTheme"
    
    private init() {
        // Inicializar com valor padrão
        self.currentTheme = .system
        self.colorScheme = nil
        
        // Carregar tema salvo na inicialização
        loadSavedTheme()
    }
    
    // MARK: - Public Methods
    
    /// Define o tema do aplicativo
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        
        switch theme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil
        }
        
        // Salva a preferência do usuário
        UserDefaults.standard.setValue(theme.rawValue, forKey: userDefaultsKey)
        
        let colorSchemeName: String
        switch colorScheme {
        case .light:
            colorSchemeName = "light"
        case .dark:
            colorSchemeName = "dark"
        case nil:
            colorSchemeName = "system"
        @unknown default:
            colorSchemeName = "unknown"
        }
        Logger.shared.debug("Tema alterado para \(theme.rawValue), ColorScheme aplicado: \(colorSchemeName)", context: "ThemeManager")
    }
    
    /// Carrega a preferência de tema salva
    func loadSavedTheme() {
        if let savedThemeRaw = UserDefaults.standard.string(forKey: userDefaultsKey),
           let savedTheme = AppTheme(rawValue: savedThemeRaw) {
            setTheme(savedTheme)
            
            Logger.shared.debug("Tema carregado do UserDefaults: \(savedTheme.rawValue)", context: "ThemeManager")
        } else {
            // Se não houver preferência salva, usa o padrão (sistema)
            setTheme(.system)
            
            Logger.shared.debug("Nenhuma preferência salva, usando tema do sistema", context: "ThemeManager")
        }
    }
    
    /// Alterna entre os temas disponíveis (útil para testing)
    func toggleTheme() {
        switch currentTheme {
        case .system:
            setTheme(.light)
        case .light:
            setTheme(.dark)
        case .dark:
            setTheme(.system)
        }
    }
    
    /// Retorna o ColorScheme efetivo considerando o tema atual e o sistema
    func effectiveColorScheme(systemColorScheme: ColorScheme) -> ColorScheme {
        return colorScheme ?? systemColorScheme
    }
    
    /// Verifica se está usando o tema dark (considerando sistema)
    func isDarkMode(systemColorScheme: ColorScheme) -> Bool {
        let effective = effectiveColorScheme(systemColorScheme: systemColorScheme)
        return effective == .dark
    }
    
    /// Acesso direto ao AdaptiveColorSystem para o tema atual
    /// NOTA: Principalmente útil para textos. Gradientes já são automáticos via xcassets.
    func adaptiveColors(for systemColorScheme: ColorScheme) -> AdaptiveColorSystem.Current {
        let effective = effectiveColorScheme(systemColorScheme: systemColorScheme)
        return AdaptiveColorSystem.current(for: effective)
    }
}

/// Temas disponíveis no aplicativo
enum AppTheme: String {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

/// Modificador para aplicar o tema do aplicativo
struct ThemeModifier: ViewModifier {
    // Using direct reference since ThemeManager.shared is @Observable singleton
    private var themeManager: ThemeManager { ThemeManager.shared }

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    /// Aplica o tema gerenciado pelo ThemeManager
    func withAppTheme() -> some View {
        modifier(ThemeModifier())
    }
    
    /// Aplica o tema e fornece acesso ao AdaptiveColorSystem no ambiente
    func withAdaptiveTheme() -> some View {
        self.modifier(ThemeModifier())
            .environment(\.adaptiveColorSystem, AdaptiveColorSystem.self)
    }
}

// MARK: - Environment Extensions

/// Chave de Environment para acessar o AdaptiveColorSystem
private struct AdaptiveColorSystemKey: EnvironmentKey {
    static let defaultValue: AdaptiveColorSystem.Type = AdaptiveColorSystem.self
}

extension EnvironmentValues {
    var adaptiveColorSystem: AdaptiveColorSystem.Type {
        get { self[AdaptiveColorSystemKey.self] }
        set { self[AdaptiveColorSystemKey.self] = newValue }
    }
}

// Exemplo de uso:
/*
 // Na inicialização do app
 ThemeManager.shared.loadSavedTheme()
 
 // Na sua App ou em alguma View
 @StateObject private var themeManager = ThemeManager.shared
 
 var body: some View {
     ContentView()
         .withAppTheme()
 }
 
 // Em alguma tela de configurações
 Button("Tema Claro") {
     themeManager.setTheme(.light)
 }
 
 Button("Tema Escuro") {
     themeManager.setTheme(.dark)
 }
 
 Button("Seguir o Sistema") {
     themeManager.setTheme(.system)
 }
 */
