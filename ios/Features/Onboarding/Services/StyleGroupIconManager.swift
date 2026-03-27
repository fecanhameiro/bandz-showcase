//
//  StyleGroupIconManager.swift
//  Bandz
//
//  Created by Claude Code on 23/01/25.
//

import SwiftUI
import UIKit

// MARK: - StyleGroupIconManager

/// Gerenciador centralizado para ícones de grupos de estilo musical
/// 
/// Responsabilidades:
/// - Carregar ícones do Asset Catalog baseado no nome
/// - Fallback automático para ícone padrão quando asset não encontrado
/// - Logging e métricas de uso de fallback
/// - Configuração global do ícone padrão
struct StyleGroupIconManager {
    
    // MARK: - Configuration
    
    /// Nome do ícone padrão usado como fallback
    /// Configurável globalmente para fácil manutenção
    static var fallbackIconName: String = "bandz_place_holder"
    
    /// Habilitação de logs de debug para desenvolvimento
    static var isDebugLoggingEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Metrics & Analytics
    
    /// Contador de usos do fallback para métricas
    private static var fallbackUsageCount: Int = 0
    
    /// Set de ícones não encontrados para evitar logs repetidos
    private static var missingIconsReported: Set<String> = []
    
    // MARK: - Public Interface
    
    /// Carrega ícone baseado no nome, com fallback automático
    /// 
    /// - Parameter iconName: Nome do ícone no Asset Catalog (ex: "rock_icon")
    /// - Returns: SwiftUI Image (asset ou fallback)
    static func loadIcon(named iconName: String) -> Image {
        
        // Validação básica do nome
        guard !iconName.isEmpty else {
            logWarning("Empty icon name provided, using fallback")
            return fallbackIcon()
        }
        
        // Tentar carregar do Asset Catalog
        if assetExists(iconName) {
            logSuccess("Icon loaded successfully: \(iconName)")
            return Image(iconName)
        } else {
            logWarning("Icon not found in Asset Catalog: \(iconName)")
            return fallbackIcon()
        }
    }
    
    /// Carrega ícone baseado no StyleGroup
    /// 
    /// - Parameter styleGroup: Grupo de estilo com informações do ícone
    /// - Returns: SwiftUI Image (asset ou fallback)
    static func loadIcon(for styleGroup: StyleGroup) -> Image {
        return loadIcon(named: styleGroup.icon)
    }
    
    /// Carrega ícone como UIImage para casos específicos
    /// 
    /// - Parameter iconName: Nome do ícone no Asset Catalog
    /// - Returns: UIImage opcional (nil se não encontrado e fallback falhar)
    static func loadUIImage(named iconName: String) -> UIImage? {
        
        guard !iconName.isEmpty else {
            logWarning("Empty icon name provided for UIImage")
            return UIImage(named: fallbackIconName)
        }
        
        if let image = UIImage(named: iconName) {
            logSuccess("UIImage loaded successfully: \(iconName)")
            return image
        } else {
            logWarning("UIImage not found: \(iconName)")
            return UIImage(named: fallbackIconName)
        }
    }
    
    // MARK: - Validation & Utilities
    
    /// Verifica se um asset existe no Asset Catalog
    /// 
    /// - Parameter assetName: Nome do asset para verificar
    /// - Returns: true se asset existe, false caso contrário
    static func assetExists(_ assetName: String) -> Bool {
        // UIImage(named:) retorna nil se asset não existir
        return UIImage(named: assetName) != nil
    }
    
    /// Verifica se o ícone padrão de fallback existe
    /// 
    /// - Returns: true se fallback existe, false se há problema de configuração
    static func fallbackIconExists() -> Bool {
        return assetExists(fallbackIconName)
    }
    
    /// Lista todos os ícones que foram reportados como missing
    /// 
    /// - Returns: Array de nomes de ícones não encontrados
    static func getMissingIconsReport() -> [String] {
        return Array(missingIconsReported).sorted()
    }
    
    /// Quantidade de vezes que o fallback foi usado
    /// 
    /// - Returns: Número de usos do fallback icon
    static func getFallbackUsageCount() -> Int {
        return fallbackUsageCount
    }
    
    // MARK: - Private Implementation
    
    /// Retorna o ícone de fallback configurado
    private static func fallbackIcon() -> Image {
        fallbackUsageCount += 1
        
        // Verificar se fallback existe (problema de configuração)
        if !fallbackIconExists() {
            logError("CRITICAL: Fallback icon '\(fallbackIconName)' not found in Asset Catalog!")
            // Retorna SF Symbol como último recurso
            return Image(systemName: "music.note")
        }
        
        // Log analytics para métricas
        logFallbackUsage()
        
        return Image(fallbackIconName)
    }
    
    // MARK: - Logging & Analytics
    
    /// Log de sucesso no carregamento
    private static func logSuccess(_ message: String) {
        guard isDebugLoggingEnabled else { return }
        Logger.shared.info("StyleGroupIconManager: \(message)", context: "StyleGroupIconManager")
    }
    
    /// Log de warning para ícones não encontrados
    private static func logWarning(_ message: String) {
        guard isDebugLoggingEnabled else { return }
        Logger.shared.warning("StyleGroupIconManager: \(message)", context: "StyleGroupIconManager")
        
        // Extrair nome do ícone da mensagem para tracking
        if message.contains("not found") {
            let components = message.components(separatedBy: ": ")
            if let iconName = components.last {
                missingIconsReported.insert(iconName)
            }
        }
    }
    
    /// Log de erro crítico
    private static func logError(_ message: String) {
        Logger.shared.error("StyleGroupIconManager ERROR: \(message)", context: "StyleGroupIconManager")
        
        // Em produção, reportar erro crítico para analytics
        #if !DEBUG
        AnalyticsManager.shared.logCustomEvent("style_group_icon_critical_error", parameters: [
            "message": message,
            "fallback_icon": fallbackIconName
        ])
        #endif
    }
    
    /// Log de uso do fallback para analytics
    private static func logFallbackUsage() {
        #if !DEBUG
        // Em produção, enviar evento de analytics
        AnalyticsManager.shared.logCustomEvent("style_group_icon_fallback_used", parameters: [
            "fallback_icon": fallbackIconName,
            "usage_count": fallbackUsageCount
        ])
        #endif
    }
    
    // MARK: - Configuration Management
    
    /// Atualiza o ícone de fallback globalmente
    /// 
    /// - Parameter newFallbackIcon: Nome do novo ícone de fallback
    /// - Returns: true se o novo ícone existe, false se inválido
    @discardableResult
    static func setFallbackIcon(_ newFallbackIcon: String) -> Bool {
        guard !newFallbackIcon.isEmpty && assetExists(newFallbackIcon) else {
            logError("Attempted to set invalid fallback icon: \(newFallbackIcon)")
            return false
        }
        
        let oldFallback = fallbackIconName
        fallbackIconName = newFallbackIcon
        
        logSuccess("Fallback icon updated: \(oldFallback) → \(newFallbackIcon)")
        return true
    }
    
    /// Reset das métricas de uso (útil para testes)
    static func resetMetrics() {
        fallbackUsageCount = 0
        missingIconsReported.removeAll()
        
        if isDebugLoggingEnabled {
            Logger.shared.debug("StyleGroupIconManager: Metrics reset", context: "StyleGroupIconManager")
        }
    }
}

// MARK: - StyleGroupIconManager Extensions

extension StyleGroupIconManager {
    
    /// Configurações predefinidas para diferentes contextos
    enum Configuration {
        case production
        case development
        case testing
        
        var fallbackIconName: String {
            switch self {
            case .production, .development:
                return "bandz_place_holder"
            case .testing:
                return "bandz_place_holder" // Mesmo para testes, mas pode ser customizado
            }
        }
        
        var debugLoggingEnabled: Bool {
            switch self {
            case .production:
                return false
            case .development, .testing:
                return true
            }
        }
    }
    
    /// Aplica configuração predefinida
    /// 
    /// - Parameter config: Configuração a ser aplicada
    static func applyConfiguration(_ config: Configuration) {
        fallbackIconName = config.fallbackIconName
        isDebugLoggingEnabled = config.debugLoggingEnabled
        
        logSuccess("Configuration applied: \(config)")
    }
}

// MARK: - SwiftUI Integration Helper

extension Image {
    
    /// Inicialização conveniente usando StyleGroupIconManager
    /// 
    /// - Parameter styleGroupIcon: Nome do ícone do grupo de estilo
    /// - Returns: Image com fallback automático
    init(styleGroupIcon iconName: String) {
        self = StyleGroupIconManager.loadIcon(named: iconName)
    }
    
    /// Inicialização conveniente usando StyleGroup
    /// 
    /// - Parameter styleGroup: Grupo de estilo
    /// - Returns: Image com fallback automático
    init(styleGroup: StyleGroup) {
        self = StyleGroupIconManager.loadIcon(for: styleGroup)
    }
}

// MARK: - Development & Debug Helpers

#if DEBUG
extension StyleGroupIconManager {
    
    /// Testa todos os ícones de uma lista de StyleGroups
    /// Útil para validação durante desenvolvimento
    /// 
    /// - Parameter styleGroups: Lista de grupos para testar
    /// - Returns: Relatório de ícones faltando
    static func validateIcons(for styleGroups: [StyleGroup]) -> [String] {
        var missingIcons: [String] = []
        
        for styleGroup in styleGroups {
            if !assetExists(styleGroup.icon) {
                missingIcons.append(styleGroup.icon)
            }
        }
        
        if !missingIcons.isEmpty {
            Logger.shared.warning("StyleGroupIconManager Validation: Missing icons=\(missingIcons), total=\(styleGroups.count), missing%=\(Double(missingIcons.count) / Double(styleGroups.count) * 100)%", context: "StyleGroupIconManager")
        }
        
        return missingIcons
    }
    
    /// Gera relatório detalhado de uso
    /// 
    /// - Returns: String com relatório completo
    static func generateUsageReport() -> String {
        var report = "📊 StyleGroupIconManager Usage Report\n"
        report += "=====================================\n"
        report += "Fallback icon: \(fallbackIconName)\n"
        report += "Fallback usage count: \(fallbackUsageCount)\n"
        report += "Missing icons reported: \(missingIconsReported.count)\n"
        
        if !missingIconsReported.isEmpty {
            report += "Missing icons:\n"
            for icon in missingIconsReported.sorted() {
                report += "  • \(icon)\n"
            }
        }
        
        report += "Fallback exists: \(fallbackIconExists() ? "✅" : "❌")\n"
        report += "Debug logging: \(isDebugLoggingEnabled ? "✅" : "❌")\n"
        
        return report
    }
    
    /// Mock para testes
    static func createMockStyleGroups() -> [StyleGroup] {
        return [
            StyleGroup.mock(icon: "rock_icon"),
            StyleGroup.mock(icon: "jazz_icon"),
            StyleGroup.mock(icon: "nonexistent_icon"), // Para testar fallback
            StyleGroup.mock(icon: "pop_icon"),
            StyleGroup.mock(icon: "") // Para testar validação
        ]
    }
}
#endif
