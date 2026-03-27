import SwiftUI
import FirebaseAuth
import Observation

// MARK: - Onboarding Completion Destination

enum OnboardingCompletionDestination {
    case home    // Fluxo normal - vai para home
    case auth    // Usuário clicou "Já tenho usuário" - vai para login
}

enum OnboardingPersistenceState: Equatable {
    case pending
    case saving
    case saved
    case failed(String)
}

// MARK: - OnboardingCoordinator

/// Coordenador de navegação para o fluxo de onboarding
/// Gerencia transições entre etapas e estado de navegação
@MainActor
@Observable
final class BandzOnboardingCoordinator: Coordinator {

    // MARK: - Observable Properties

    var navigationPath = NavigationPath()
    var isPresenting = false
    var currentStep: OnboardingStep = .welcome
    private(set) var persistenceState: OnboardingPersistenceState = .pending

    /// Flag que indica que o usuário já está autenticado e precisa apenas completar preferências
    var isReturningUser = false

    // Coordinator foca apenas em navegação - UI alerts são responsabilidade das Views

    // MARK: - Private Properties

    @ObservationIgnored let userDataManager: UserDataManager
    @ObservationIgnored private let authService: FirebaseAuthService
    @ObservationIgnored private let genreService: GenreService
    @ObservationIgnored private let placeService: PlaceService
    @ObservationIgnored private let logger = Logger.shared
    @ObservationIgnored private let loggingContext = "OnboardingCoordinator"

    // ProgressManager removido na simplificação

    /// Flag para garantir que preload só seja executado uma vez quando usuário demonstra intenção real
    @ObservationIgnored private var hasUserStartedOnboarding = false

    /// Serviços de streaming conectados durante o onboarding (armazenados por id)
    private(set) var connectedStreamingServiceIds: Set<String> = []

    /// Serviço usado como referência principal para restaurar estado de seleção
    @ObservationIgnored private var primaryStreamingServiceId: String?

    /// Flag para evitar finalização múltipla quando streaming já populou dados
    @ObservationIgnored private var hasAutoFinalizeTriggered = false

    /// Whether streaming returned actual genre results (false = empty/all zeros → show genre selection)
    private(set) var hasDiscoveredGenres = false

    /// Guard contra navegação concorrente (toques rápidos em back/forward)
    @ObservationIgnored private var isNavigating = false

    /// Timestamp de quando o step atual foi exibido (para calcular duração no funil)
    @ObservationIgnored private var stepViewedAt: Date = Date()

    /// Step inicial para returning users (impede back navigation além deste ponto)
    @ObservationIgnored var returningUserStartStep: OnboardingStep?

    /// Serviços que suportam finalização automática (quando dados completos são coletados)
    @ObservationIgnored private let autoFinalizeStreamingServiceIds: Set<String> = ["spotify"]
    
    
    // Completion handler with optional destination parameter
    var onComplete: ((OnboardingCompletionDestination?) -> Void)?
    
    var hasConnectedStreamingService: Bool {
        return !connectedStreamingServiceIds.isEmpty
    }
    
    var primaryConnectedStreamingService: StreamingService? {
        if let primaryId = primaryStreamingServiceId,
           let service = StreamingService.service(for: primaryId) {
            return service
        }
        guard let fallbackId = connectedStreamingServiceIds.first else { return nil }
        return StreamingService.service(for: fallbackId)
    }
    
    private var shouldAutoFinalizeStreamingData: Bool {
        return !autoFinalizeStreamingServiceIds.isDisjoint(with: connectedStreamingServiceIds)
    }
    
    func isStreamingServiceConnected(_ service: StreamingService) -> Bool {
        return connectedStreamingServiceIds.contains(service.id)
    }
    
    // MARK: - Initialization
    
    init(
        userDataManager: UserDataManager,
        authService: FirebaseAuthService,
        genreService: GenreService,
        placeService: PlaceService,
        onComplete: @escaping (OnboardingCompletionDestination?) -> Void
    ) {
        self.userDataManager = userDataManager
        self.authService = authService
        self.genreService = genreService
        self.placeService = placeService
        self.onComplete = onComplete
        
    }
    
    // MARK: - Coordinator Protocol
    
    typealias Route = OnboardingStep // Type-safe navigation com enum
    
    func start() {
        Task {
            do {
                if !isReturningUser {
                    // Start new onboarding session with UserDataManager (creates Firebase anonymous user)
                    try await userDataManager.startNewOnboardingSession()

                    // No checkpoint restore — if app closes mid-onboarding, user starts fresh
                } else if userDataManager.currentUserData == nil {
                    // Returning user with no cached data (new user who logged in via auth flow)
                    // Initialize user data from Firebase Auth so preference updates work
                    if let firebaseUser = Auth.auth().currentUser {
                        let authMethod = Self.detectAuthMethod(from: firebaseUser)
                        let userData = User(
                            userID: firebaseUser.uid,
                            authMethod: authMethod,
                            email: firebaseUser.email,
                            phoneNumber: firebaseUser.phoneNumber,
                            name: firebaseUser.displayName,
                            profileImageURL: firebaseUser.photoURL?.absoluteString
                        )
                        userDataManager.updateUser(userData)
                        logger.info("Initialized user data from Firebase Auth for preferences onboarding",
                                    metadata: ["userID": firebaseUser.uid, "authMethod": authMethod.rawValue],
                                    context: loggingContext)
                    }
                }

                // NOTE: Preload removido daqui - agora é ativado apenas quando usuário demonstra intenção real
                // de continuar o onboarding (quando clica "Get Started" e navega para próxima tela)
            } catch {
                logger.error("Failed to initialize onboarding: \(error)", context: loggingContext)
            }
        }
    }

    /// Detecta o AuthMethod a partir do provider do Firebase Auth user
    private static func detectAuthMethod(from firebaseUser: FirebaseAuth.User) -> AuthMethod {
        guard let providerID = firebaseUser.providerData.first?.providerID else { return .anonymous }
        switch providerID {
        case "google.com": return .google
        case "facebook.com": return .facebook
        case "apple.com": return .apple
        case "phone": return .phone
        default: return .anonymous
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Navega para próxima etapa - TYPE-SAFE com otimização para integrações de streaming
    func navigateToNextStep() async {
        guard !isNavigating else { return }
        isNavigating = true
        defer { isNavigating = false }

        guard let nextStep = currentStep.nextStep(hasStreamingConnected: hasConnectedStreamingService, hasDiscoveredGenres: hasDiscoveredGenres, isUserAuthenticated: isReturningUser) else {
            logger.debug("Navigation: Already at final step (\(currentStep.displayName))", context: loggingContext)
            return
        }

        // Detectar quando usuário sai do welcome screen - indica intenção real de fazer onboarding
        if currentStep == .welcome && !hasUserStartedOnboarding {
            await userStartedOnboarding()
        }

        let connectedServicesList = Array(connectedStreamingServiceIds).joined(separator: ", ")
        if hasConnectedStreamingService && currentStep == .streamingSelection {
            logger.debug("Navigation: Streaming connected (\(connectedServicesList)) - skipping favoriteGenres -> locationPermission", context: loggingContext)
        }
        if hasConnectedStreamingService && currentStep == .notificationPermission {
            logger.debug("Navigation: Streaming connected (\(connectedServicesList)) - skipping authSignup -> completed", context: loggingContext)
        }

        await performNavigation(to: nextStep)
    }
    
    /// Navega para step específico - TYPE-SAFE
    /// Chamado externamente (ex: returning user flow). Aplica guard de navegação concorrente.
    func navigateToStep(_ step: OnboardingStep) async {
        guard !isNavigating else { return }
        isNavigating = true
        defer { isNavigating = false }

        await performNavigation(to: step)
    }

    /// Execução interna de navegação (sem guard — chamado por métodos que já fizeram o guard)
    private func performNavigation(to step: OnboardingStep) async {
        // Detectar quando usuário navega para qualquer step após welcome - indica intenção real
        if currentStep == .welcome && step != .welcome && !hasUserStartedOnboarding {
            await userStartedOnboarding()
        }

        // Funnel analytics: registrar duração no step anterior + step_viewed no próximo
        let previousStep = currentStep
        let stepDuration = Date().timeIntervalSince(stepViewedAt)
        AnalyticsManager.shared.logCustomEvent("onboarding_step_completed", parameters: [
            "step_name": previousStep.rawValue,
            "step_number": previousStep.stepNumber,
            "duration_seconds": Int(stepDuration),
            "has_streaming": hasConnectedStreamingService
        ])
        AnalyticsManager.shared.logCustomEvent("onboarding_step_viewed", parameters: [
            "step_name": step.rawValue,
            "step_number": step.stepNumber
        ])
        stepViewedAt = Date()

        // Atualizar currentStep e path ANTES de side-effects (auto-finalization)
        // para garantir que a UI reflita o step correto mesmo se finalization falhar
        currentStep = step
        navigationPath.append(step)

        logger.debug("Type-Safe Navigation: Moving to \(step.displayName) (\(step.rawValue))", context: loggingContext)
        logger.debug("   Step: \(step.stepNumber)/\(OnboardingStep.totalSteps)", context: loggingContext)
        logger.debug("   Progress: \(String(format: "%.1f", step.progressPercentage * 100))%", context: loggingContext)
        if hasConnectedStreamingService {
            logger.debug("   Streaming Connected: Skip logic ativo (\(Array(connectedStreamingServiceIds)))", context: loggingContext)
        }

        // All data stays in-memory only — persistence happens on completion screen via persistOnboardingData()
    }
    
    /// Volta para etapa anterior - TYPE-SAFE com otimização para integrações de streaming
    func navigateBack() async {
        guard !isNavigating else { return }
        isNavigating = true
        defer { isNavigating = false }

        // Returning user: impedir back navigation além do step inicial
        if let startStep = returningUserStartStep, currentStep == startStep {
            logger.debug("Navigation: Returning user at start step (\(startStep.displayName)) - cannot go back", context: loggingContext)
            return
        }

        guard let previousStep = currentStep.previousStep(hasStreamingConnected: hasConnectedStreamingService, hasDiscoveredGenres: hasDiscoveredGenres, isUserAuthenticated: isReturningUser) else {
            logger.debug("Navigation: Already at first step (\(currentStep.displayName))", context: loggingContext)
            return
        }

        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            currentStep = previousStep

            let connectedServicesList = Array(connectedStreamingServiceIds).joined(separator: ", ")
            if hasConnectedStreamingService && currentStep == .locationPermission {
                logger.debug("Navigation: Streaming connected (\(connectedServicesList)) - skipping back favoriteGenres -> streamingSelection", context: loggingContext)
            }
            logger.debug("Type-Safe Navigation: Going back to \(previousStep.displayName)", context: loggingContext)
        }
    }
    
    /// Pula etapa opcional - TYPE-SAFE
    func skipCurrentStep() async {
        guard !isNavigating else { return }

        guard currentStep.isSkippable else {
            logger.debug("Navigation: Step \(currentStep.displayName) cannot be skipped", context: loggingContext)
            return
        }

        logger.debug("Navigation: Skipping \(currentStep.displayName)", context: loggingContext)

        AnalyticsManager.shared.logCustomEvent("onboarding_step_skipped", parameters: [
            "step_name": currentStep.rawValue,
            "step_number": currentStep.stepNumber
        ])

        // navigateToNextStep já aplica isNavigating guard internamente
        await navigateToNextStep()
    }
    
    /// Navega diretamente para tela de login (botão "Já tenho usuário")
    func navigateToLogin() async {
        logger.debug("navigateToLogin() called - skipping to auth", context: loggingContext)
        
        // NÃO marca onboarding como completo - apenas vai para auth flow
        // O onboarding só será completo após login bem-sucedido
        onComplete?(.auth)
    }
    
    /// Método público para ativar preload quando usuário demonstra intenção de fazer onboarding
    /// Pode ser chamado por Views ou outros componentes quando detectam intenção do usuário
    func activatePreloadOnUserIntent() async {
        await userStartedOnboarding()
    }
    
    /// Marca que o usuário conectou com um serviço de streaming com sucesso
    /// Permite otimizar navegação pulando etapas redundantes
    func markStreamingConnected(_ service: StreamingService, discoveredGenres: Bool) {
        connectedStreamingServiceIds.insert(service.id)
        primaryStreamingServiceId = service.id
        hasDiscoveredGenres = discoveredGenres

        logger.debug("Streaming service connected (\(service.id)) - discoveredGenres: \(discoveredGenres)", context: loggingContext)
    }
    
    /// Reseta o estado de conexão do serviço de streaming informado (ou todos, se nil)
    func clearStreamingConnection(_ service: StreamingService? = nil) {
        if let service {
            connectedStreamingServiceIds.remove(service.id)
        } else {
            connectedStreamingServiceIds.removeAll()
        }
        
        if let primaryId = primaryStreamingServiceId, !connectedStreamingServiceIds.contains(primaryId) {
            primaryStreamingServiceId = connectedStreamingServiceIds.first
        }
        
        if connectedStreamingServiceIds.isEmpty {
            primaryStreamingServiceId = nil
        }
        
        hasAutoFinalizeTriggered = false
        hasDiscoveredGenres = false

        // Clear genres when disconnecting streaming service
        userDataManager.updateGenres([])

        logger.debug("Streaming connection reset (remaining: \(Array(connectedStreamingServiceIds)))", context: loggingContext)
    }
    
    /// Método chamado quando usuário demonstra intenção real de fazer onboarding
    /// Ativa preload de dados apenas neste momento para otimizar performance
    private func userStartedOnboarding() async {
        guard !hasUserStartedOnboarding else {
            logger.debug("User already started onboarding, skipping preload", context: loggingContext)
            return
        }

        hasUserStartedOnboarding = true

        logger.debug("User started onboarding - activating background preload", context: loggingContext)
        
        // Iniciar preload de dados em background agora que usuário demonstrou intenção real
        startBackgroundPreloading()
    }
    
    /// Persists all onboarding data to Firebase. Called when completion screen appears.
    func persistOnboardingData() async {
        guard persistenceState != .saving && persistenceState != .saved else { return }

        persistenceState = .saving
        logger.info("Persisting onboarding data to Firestore", context: loggingContext)

        do {
            // Returning user: finalize with Firebase user data (updates authMethod, email, name, etc.)
            if isReturningUser {
                if let firebaseUser = Auth.auth().currentUser {
                    try userDataManager.finalizeOnboarding(with: firebaseUser)
                } else if var userData = userDataManager.currentUserData {
                    userData.isOnboardingCompleted = true
                    userDataManager.updateUser(userData)
                }
            }

            // Auto-finalize streaming data (Spotify) if needed
            if shouldAutoFinalizeStreamingData && !hasAutoFinalizeTriggered {
                hasAutoFinalizeTriggered = true
                if connectedStreamingServiceIds.contains(StreamingService.spotify.id) {
                    _ = try await OnboardingFinalizer.finalizeUserData(
                        authMethod: .spotify,
                        userDataManager: userDataManager,
                        authService: authService
                    )
                    logger.info("Streaming data auto-finalized before persistence", context: loggingContext)
                }
            }

            try await userDataManager.persistCurrentUserData()
            persistenceState = .saved
            logger.info("Onboarding data persisted to Firestore successfully", context: loggingContext)
        } catch {
            persistenceState = .failed(error.localizedDescription)
            hasAutoFinalizeTriggered = false
            logger.error("Failed to persist onboarding data: \(error)", context: loggingContext)
        }
    }

    /// Completa onboarding e navega para app principal (fluxo normal)
    func completeOnboarding() async {
        logger.debug("completeOnboarding() called", context: loggingContext)

        guard persistenceState == .saved else {
            if persistenceState == .saving {
                logger.debug("completeOnboarding called while still saving — ignoring", context: loggingContext)
                return
            }
            if case .failed = persistenceState {
                logger.debug("completeOnboarding called after failure — retrying persistence", context: loggingContext)
                await persistOnboardingData()
                guard persistenceState == .saved else { return }
            }
            return
        }

        // Mark onboarding as completed in UserManager
        UserManager.shared.hasCompletedOnboarding = true

        // Fluxo normal - vai para home (nil = comportamento padrão)
        onComplete?(nil)
    }
    
    // MARK: - Finalization Methods (using OnboardingFinalizer)

    /// Finaliza onboarding com Google (auth já foi feita na view)
    func finishOnboardingWithGoogle() async throws {
        _ = try await OnboardingFinalizer.finalizeUserData(
            authMethod: .google,
            userDataManager: userDataManager,
            authService: authService
        )
        await performNavigation(to: .completed)
    }

    /// Finaliza onboarding com Facebook (auth já foi feita na view)
    func finishOnboardingWithFacebook() async throws {
        _ = try await OnboardingFinalizer.finalizeUserData(
            authMethod: .facebook,
            userDataManager: userDataManager,
            authService: authService
        )
        await performNavigation(to: .completed)
    }

    /// Finaliza dados do onboarding com Spotify (auth já foi feita na view)
    /// Versão que só processa dados, sem navegação - para evitar loops
    private func finishOnboardingWithSpotifyData() async throws {
        _ = try await OnboardingFinalizer.finalizeUserData(
            authMethod: .spotify,
            userDataManager: userDataManager,
            authService: authService
        )
        // ⚠️ Não navegar aqui - já estamos no step .completed
    }

    /// Finaliza onboarding com Spotify (auth já foi feita na view)
    /// Versão completa com navegação - para uso direto em views
    func finishOnboardingWithSpotify() async throws {
        try await finishOnboardingWithSpotifyData()
        if currentStep != .completed {
            await performNavigation(to: .completed)
        }
    }

    /// Finaliza onboarding com Apple (auth já foi feita na view)
    func finishOnboardingWithApple() async throws {
        _ = try await OnboardingFinalizer.finalizeUserData(
            authMethod: .apple,
            userDataManager: userDataManager,
            authService: authService
        )
        await performNavigation(to: .completed)
    }

    /// Finaliza onboarding com Phone (auth já foi feita na view)
    func finishOnboardingWithPhone() async throws {
        _ = try await OnboardingFinalizer.finalizeUserData(
            authMethod: .phone,
            userDataManager: userDataManager,
            authService: authService
        )
        await performNavigation(to: .completed)
    }

    /// Finaliza onboarding anonimamente (persistence deferred to completion screen)
    func finishOnboardingAnonymously() async throws {
        if var userData = userDataManager.currentUserData {
            userData.isOnboardingCompleted = true
            userDataManager.updateUser(userData)
        }
        logger.info("Anonymous onboarding finalized in-memory", context: loggingContext)
        await performNavigation(to: .completed)
    }
    
    
    /// Cancela onboarding (volta para início)
    func cancelOnboarding() async {
        // Views devem mostrar confirmação e chamar resetOnboarding() se confirmado
        await resetOnboarding()
    }
    
    /// Reset onboarding (chamado após confirmação da View)
    func resetOnboarding() async {
        await resetNavigation()
    }
    
    /// Reset navegação para estado inicial
    private func resetNavigation() async {
        currentStep = .welcome
        navigationPath = NavigationPath()
        returningUserStartStep = nil
    }
    
   
    
    // MARK: - Utility Methods
    
    /// Verificação type-safe de navegação
    @MainActor
    func canNavigateToStep(_ step: OnboardingStep) -> Bool {
        guard step.isInMainFlow else { return false }
        return true
    }
    
    // MARK: - View Factory (movido para OnboardingViewFactory)
    // Coordinator não deve conhecer detalhes de construção de Views
    // Views devem ser injetadas via DI ou criadas por ViewFactory dedicado
}

// MARK: - Supporting Types

// OnboardingAlert movido para Views que precisarem
// Coordinator não deve gerenciar estruturas de UI

// MARK: - Navigation Extensions

extension BandzOnboardingCoordinator {
    /// Navega para step por índice - TYPE-SAFE
    func navigateToStepAtIndex(_ index: Int) async {
        let steps = OnboardingStep.mainFlow
        guard index >= 0 && index < steps.count else {
            logger.warning("Invalid step index: \(index)", context: loggingContext)
            return
        }
        
        await navigateToStep(steps[index])
    }
    
    /// Índice do step atual
    @MainActor
    var currentStepIndex: Int {
        return OnboardingStep.mainFlow.firstIndex(of: currentStep) ?? 0
    }
    
    /// Total de steps no fluxo principal
    var totalSteps: Int {
        return OnboardingStep.totalSteps
    }
    
    // MARK: - Background Data Preloading
    
    /// Inicia preload de dados em background para melhorar UX
    /// Executa apenas quando usuário demonstra intenção real de fazer onboarding
    /// Roda completamente em background threads para não bloquear UI
    private func startBackgroundPreloading() {
        logger.debug("Background preload initiated for genres and places (non-blocking)", context: loggingContext)

        // Preload em paralelo — se falhar, as telas individuais fazem retry com loading state
        genreService.startStyleGroupsPreloading()
        placeService.startPlacesPreloading()
    }
}

// MARK: - Debug Extensions

extension BandzOnboardingCoordinator {
    @MainActor
    func printNavigationInfo() {
        let info = """
        OnboardingCoordinator Info:
           Current Step: \(currentStep.displayName) (\(currentStep.rawValue))
           Step Number: \(currentStep.stepNumber)/\(OnboardingStep.totalSteps)
           Progress: \(String(format: "%.1f", currentStep.progressPercentage * 100))%
           Navigation Path Count: \(navigationPath.count)
           Is Presenting: \(isPresenting)
           Can Skip Current: \(currentStep.isSkippable)
           Requires Input: \(currentStep.requiresUserInput)
           Next Step: \(currentStep.next?.displayName ?? "None")
           Previous Step: \(currentStep.previous?.displayName ?? "None")
        """
        logger.debug(info, context: loggingContext)
    }
}
