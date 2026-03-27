//
//  OnboardingStep.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 24/06/25.
//

import Foundation

// MARK: - OnboardingStep

/// Enum que define todos os steps do onboarding com navegação type-safe
enum OnboardingStep: String, CaseIterable, Hashable, Codable {
    case welcome = "welcome"
    case streamingConnectionsInfo = "streamingConnectionsInfo"
    case streamingSelection = "streamingSelection"
    case favoriteGenres = "favoriteGenres"
    case locationPermission = "locationPermission"
    case favoritePlaces = "favoritePlaces"
    case notificationPermission = "notificationPermission"
    case authSignup = "authSignup"
    case completed = "completed"
    
    // MARK: - Navigation Logic
    
    /// Retorna o próximo step na sequência
    var next: OnboardingStep? {
        switch self {
        case .welcome:
            return .streamingConnectionsInfo
        case .streamingConnectionsInfo:
            return .streamingSelection
        case .streamingSelection:
            return .favoriteGenres
        case .favoriteGenres:
            return .locationPermission
        case .locationPermission:
            return .favoritePlaces
        case .favoritePlaces:
            return .notificationPermission
        case .notificationPermission:
            return .authSignup
        case .authSignup:
            return .completed
        case .completed:
            return nil // Último step
        }
    }
    
    /// Retorna o próximo step considerando se um serviço de streaming foi conectado com sucesso
    /// - Parameter hasStreamingConnected: indica se o usuário conectou com algum serviço
    /// - Returns: próximo step otimizado baseado no contexto
    func nextStep(hasStreamingConnected: Bool = false, hasDiscoveredGenres: Bool = false, isUserAuthenticated: Bool = false) -> OnboardingStep? {
        switch self {
        case .streamingSelection:
            // Pular seleção de gêneros APENAS se conectou E descobriu gêneros
            // Se gêneros vieram vazios, mostrar seleção manual
            return (hasStreamingConnected && hasDiscoveredGenres) ? .locationPermission : .favoriteGenres
        case .notificationPermission:
            // Pular authSignup se streaming conectado OU se usuário já autenticado
            return (hasStreamingConnected || isUserAuthenticated) ? .completed : .authSignup
        default:
            // Para todos os outros steps, usar lógica padrão
            return next
        }
    }
    
    /// Retorna o step anterior na sequência
    var previous: OnboardingStep? {
        switch self {
        case .welcome:
            return nil // Primeiro step
        case .streamingConnectionsInfo:
            return .welcome
        case .streamingSelection:
            return .streamingConnectionsInfo
        case .favoriteGenres:
            return .streamingSelection
        case .locationPermission:
            return .favoriteGenres
        case .favoritePlaces:
            return .locationPermission
        case .notificationPermission:
            return .favoritePlaces
        case .authSignup:
            return .notificationPermission
        case .completed:
            return .authSignup
        }
    }
    
    /// Retorna o step anterior considerando se um serviço de streaming foi conectado com sucesso
    /// - Parameter hasStreamingConnected: indica se o usuário conectou com algum serviço
    /// - Returns: step anterior otimizado baseado no contexto
    func previousStep(hasStreamingConnected: Bool = false, hasDiscoveredGenres: Bool = false, isUserAuthenticated: Bool = false) -> OnboardingStep? {
        switch self {
        case .locationPermission:
            // Se conectou E descobriu gêneros, voltar direto para streamingSelection
            return (hasStreamingConnected && hasDiscoveredGenres) ? .streamingSelection : .favoriteGenres
        case .completed:
            // Se streaming conectado OU usuário já autenticado, anterior foi notificationPermission
            return (hasStreamingConnected || isUserAuthenticated) ? .notificationPermission : .authSignup
        default:
            // Para todos os outros steps, usar lógica padrão
            return previous
        }
    }
    
    /// Indica se este step pode ser pulado
    var isSkippable: Bool {
        switch self {
        case .welcome, .completed:
            return false // Steps obrigatórios
        case .streamingConnectionsInfo, .streamingSelection, .favoriteGenres, 
             .locationPermission, .favoritePlaces, .notificationPermission, .authSignup:
            return true // Steps opcionais
        }
    }
    
    /// Indica se este step requer dados do usuário
    var requiresUserInput: Bool {
        switch self {
        case .welcome, .streamingConnectionsInfo, .completed:
            return false // Steps informativos
        case .streamingSelection, .favoriteGenres, .favoritePlaces, 
             .locationPermission, .notificationPermission, .authSignup:
            return true // Steps que coletam dados
        }
    }
    
    // MARK: - Display Properties
    
    /// Nome para display/debug
    var displayName: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .streamingConnectionsInfo:
            return "Streaming Info"
        case .streamingSelection:
            return "Streaming Selection"
        case .favoriteGenres:
            return "Favorite Genres"
        case .locationPermission:
            return "Location Permission"
        case .favoritePlaces:
            return "Favorite Places"
        case .notificationPermission:
            return "Notification Permission"
        case .authSignup:
            return "Auth & Signup"
        case .completed:
            return "Completed"
        }
    }
    
    /// Número do step para progress indicators (1-based)
    var stepNumber: Int {
        switch self {
        case .welcome:
            return 0 // Welcome não conta no progress
        case .streamingConnectionsInfo:
            return 1
        case .streamingSelection:
            return 2
        case .favoriteGenres:
            return 3
        case .locationPermission:
            return 4
        case .favoritePlaces:
            return 5
        case .notificationPermission:
            return 6
        case .authSignup:
            return 7
        case .completed:
            return 8
        }
    }
    
    /// Total de steps no fluxo principal (excluindo welcome e completed)
    /// Inclui streamingConnectionsInfo(1) até authSignup(7)
    static var totalSteps: Int {
        return 7
    }

    /// Total de steps visíveis no header (exclui welcome, authSignup e completed)
    /// O header mostra ícones apenas para steps 1-6: streaming info → notifications
    static var headerSteps: Int {
        return 6
    }
    
    // MARK: - Utility Methods
    
    /// Cria step a partir de string (fallback seguro)
    static func from(_ string: String) -> OnboardingStep {
        return OnboardingStep(rawValue: string) ?? .welcome
    }
    
    /// Retorna array com todos os steps da sequência principal
    static var mainFlow: [OnboardingStep] {
        return [
            .welcome,
            .streamingConnectionsInfo,
            .streamingSelection,
            .favoriteGenres,
            .locationPermission,
            .favoritePlaces,
            .notificationPermission,
            .authSignup,
            .completed
        ]
    }
    
    /// Verifica se é um step válido da sequência principal
    var isInMainFlow: Bool {
        return OnboardingStep.mainFlow.contains(self)
    }
}

// MARK: - Navigation Extensions

extension OnboardingStep {
    /// Avança para o próximo step se possível
    func advance() -> OnboardingStep {
        return next ?? self
    }
    
    /// Retrocede para o step anterior se possível
    func goBack() -> OnboardingStep {
        return previous ?? self
    }
    
    /// Calcula quantos steps faltam até o final
    var stepsRemaining: Int {
        let currentIndex = OnboardingStep.mainFlow.firstIndex(of: self) ?? 0
        return max(0, OnboardingStep.mainFlow.count - 1 - currentIndex)
    }
    
    /// Calcula progresso percentual (0.0 a 1.0)
    var progressPercentage: Double {
        guard stepNumber > 0 else { return 0.0 }
        return min(1.0, Double(stepNumber) / Double(OnboardingStep.totalSteps))
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension OnboardingStep {
    /// Informações de debug para logging
    var debugInfo: String {
        return """
        Step: \(displayName) (\(rawValue))
        Number: \(stepNumber)/\(OnboardingStep.totalSteps)
        Progress: \(String(format: "%.1f", progressPercentage * 100))%
        Skippable: \(isSkippable)
        Requires Input: \(requiresUserInput)
        Next: \(next?.displayName ?? "None")
        Previous: \(previous?.displayName ?? "None")
        """
    }
}
#endif
