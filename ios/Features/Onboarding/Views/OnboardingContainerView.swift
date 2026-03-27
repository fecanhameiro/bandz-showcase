//
//  OnboardingContainerView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 21/06/25.
//

import SwiftUI

/// Container principal do fluxo de onboarding
/// Responsabilidade: UI container, NavigationStack, view routing
struct OnboardingContainerView: View {

    // MARK: - Factory Method

    /// Cria OnboardingContainerView com DI configurado
    static func create(onComplete: @escaping (OnboardingCompletionDestination?) -> Void) -> OnboardingContainerView {
        return OnboardingContainerView(onComplete: onComplete)
    }

    @State private var coordinator: BandzOnboardingCoordinator
    @State private var loginViewModel: LoginViewModel
    @State private var isFinalizing = false
    @SwiftUI.Environment(AppCoordinator.self) private var appCoordinator: AppCoordinator?
    @SwiftUI.Environment(ToastCenter.self) private var toastCenter: ToastCenter?

    private let onComplete: (OnboardingCompletionDestination?) -> Void

    init(onComplete: @escaping (OnboardingCompletionDestination?) -> Void) {
        self.onComplete = onComplete

        let container = DIContainer.shared
        let coordinator = container.createOnboardingCoordinator(onComplete: onComplete)

        self._coordinator = State(initialValue: coordinator)
        self._loginViewModel = State(initialValue: container.resolveOrDefault(
            LoginViewModel.self,
            default: MainActor.assumeIsolated { LoginViewModel() }
        ))
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            OnboardingWelcomeView(
                onContinue: { Task { await coordinator.navigateToNextStep() } },
                onSkip: { Task { await coordinator.navigateToLogin() } }
            )
            .navigationDestination(for: OnboardingStep.self) { step in
                viewForStep(step)
            }
        }
        .environment(coordinator.userDataManager)
        .task {
            if appCoordinator?.isReturningUserOnboarding == true {
                coordinator.isReturningUser = true
            }
            coordinator.start()

            if appCoordinator?.isReturningUserOnboarding == true {
                // Returning user: navegar direto ao primeiro step de preferência incompleto
                await coordinator.resetOnboarding()
                let userData = coordinator.userDataManager.currentUserData
                let hasGenres = !(userData?.preferences.favoriteGenres.isEmpty ?? true)
                let startStep: OnboardingStep = hasGenres ? .locationPermission : .favoriteGenres
                coordinator.returningUserStartStep = startStep
                await coordinator.navigateToStep(startStep)
            } else if !UserManager.shared.hasCompletedOnboarding {
                if appCoordinator?.skipOnboardingWelcome == true {
                    await coordinator.resetOnboarding()
                    await coordinator.navigateToStep(.streamingConnectionsInfo)
                }
            }
        }
    }

    // MARK: - View Routing

    @ViewBuilder
    private func viewForStep(_ step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            OnboardingWelcomeView(
                onContinue: { Task { await coordinator.navigateToNextStep() } },
                onSkip: { Task { await coordinator.navigateToLogin() } }
            )

        case .streamingConnectionsInfo:
            OnboardingStreamingConnectionView(
                onContinue: { Task { await coordinator.navigateToNextStep() } },
                onBack: { Task { await coordinator.navigateBack() } },
                onNavigateToWelcome: { Task { await coordinator.resetOnboarding() } }
            )

        case .streamingSelection:
            OnboardingStreamingSelectionView(
                initiallyConnectedService: coordinator.primaryConnectedStreamingService,
                onContinue: { Task { await coordinator.navigateToNextStep() } },
                onBack: { Task { await coordinator.navigateBack() } },
                onStreamingConnected: { service, hasGenres in
                    Task { @MainActor in
                        coordinator.markStreamingConnected(service, discoveredGenres: hasGenres)
                    }
                },
                onStreamingDisconnected: { service in
                    Task { @MainActor in
                        coordinator.clearStreamingConnection(service)
                    }
                },
                onContinueWithoutConnect: {
                    Task { @MainActor in
                        await coordinator.navigateToNextStep()
                    }
                }
            )

        case .favoriteGenres:
            OnboardingGenreSelectionView(
                onContinue: { Task { await coordinator.navigateToNextStep() } },
                onBack: { Task { await coordinator.navigateBack() } }
            )

        case .locationPermission:
            OnboardingLocationView(
                onContinue: { Task { await coordinator.navigateToNextStep() } },
                onBack: { Task { await coordinator.navigateBack() } },
                onSkip: { Task { await coordinator.skipCurrentStep() } }
            )

        case .favoritePlaces:
            OnboardingFavoritePlacesView(
                onContinue: { Task { await coordinator.navigateToNextStep() } },
                onBack: { Task { await coordinator.navigateBack() } }
            )

        case .notificationPermission:
            OnboardingNotificationView(
                onContinue: { Task { await coordinator.navigateToNextStep() } },
                onBack: { Task { await coordinator.navigateBack() } }
            )

        case .authSignup:
            AuthView(
                loginViewModel: loginViewModel,
                context: .signup,
                isFinalizing: isFinalizing,
                onSpotifyLogin: {
                    Task { await handleFinalization { try await coordinator.finishOnboardingWithSpotify() } }
                },
                onGoogleLogin: {
                    Task { await handleFinalization { try await coordinator.finishOnboardingWithGoogle() } }
                },
                onFacebookLogin: {
                    Task { await handleFinalization { try await coordinator.finishOnboardingWithFacebook() } }
                },
                onAppleLogin: {
                    Task { await handleFinalization { try await coordinator.finishOnboardingWithApple() } }
                },
                onPhoneLogin: {
                    Task { await handleFinalization { try await coordinator.finishOnboardingWithPhone() } }
                },
                onAnonymousLogin: {
                    Task { await handleFinalization { try await coordinator.finishOnboardingAnonymously() } }
                }
            )

        case .completed:
            OnboardingCompletionView(
                coordinator: coordinator,
                onComplete: {
                    Task { await coordinator.completeOnboarding() }
                }
            )
        }
    }

    // MARK: - Error Handling

    private static let finalizationTimeoutNanoseconds: UInt64 = 15_000_000_000 // 15s

    private func handleFinalization(_ action: @escaping () async throws -> Void) async {
        isFinalizing = true
        defer { isFinalizing = false }
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await action()
                    // Check cancellation after action completes — if timeout already
                    // fired and cancelAll() ran, prevent coordinator side-effects.
                    try Task.checkCancellation()
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: Self.finalizationTimeoutNanoseconds)
                    throw OnboardingFinalizationError.timeout
                }
                // Wait for first to complete (success or timeout)
                try await group.next()
                group.cancelAll()
            }
        } catch is CancellationError {
            // Action was cancelled by timeout — timeout handler already ran
            Logger.shared.debug("Finalization action cancelled after timeout", context: "OnboardingContainer")
        } catch let error as OnboardingFinalizationError where error == .timeout {
            toastCenter?.error(titleKey: "auth.error.timeout")
            Logger.shared.warning("Onboarding finalization timed out after 15s", context: "OnboardingContainer")
        } catch {
            toastCenter?.error(titleKey: "auth.error.finalization_failed")
            Logger.shared.error("Onboarding finalization failed: \(error.localizedDescription)", context: "OnboardingContainer")
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingContainerView(onComplete: { _ in })
}
