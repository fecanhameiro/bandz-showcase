import Foundation

/// Registrar for Coordinator dependencies
final class CoordinatorsRegistrar: BaseRegistrar {

    func register() {
        registerAppCoordinator()
        registerFeatureCoordinators()
    }

    // MARK: - App Coordinator

    private func registerAppCoordinator() {
        container.register(AppCoordinator.self, scope: .singleton) {
            let userManager = self.safeResolveOrDefault(UserManager.self, default: MainActor.assumeIsolated { UserManager.shared }, context: "CoordinatorsRegistrar.AppCoordinator")
            let authService = self.safeResolve(FirebaseAuthService.self, context: "CoordinatorsRegistrar.AppCoordinator")
            let userDataManager = try? self.container.resolve(UserDataManager.self)
            let pushTokenService = try? self.container.resolve(PushTokenService.self)
            return self.mainActorIsolated {
                AppCoordinator(
                    userManager: userManager,
                    authService: authService,
                    userDataManager: userDataManager,
                    pushTokenService: pushTokenService
                )
            }
        }
    }

    // MARK: - Feature Coordinators

    private func registerFeatureCoordinators() {
        // AuthCoordinator - transient for specific navigation flows
        container.register(AuthCoordinator.self, scope: .transient) {
            self.mainActorIsolated { AuthCoordinator() }
        }

        // HomeCoordinator - transient for specific navigation flows
        container.register(HomeCoordinator.self, scope: .transient) {
            self.mainActorIsolated { HomeCoordinator() }
        }

        // Note: OnboardingCoordinator requires a callback and is created via factory method
    }

    // MARK: - Factory Methods

    /// Factory method for creating a coordinator with properly injected dependencies
    func coordinatorFactory<T>(_ type: T.Type) -> T {
        do {
            return try container.resolve(type)
        } catch {
            fatalError("Failed to resolve coordinator of type \(type): \(error)")
        }
    }

    /// Factory method for creating OnboardingCoordinator with proper dependencies
    func createOnboardingCoordinator(onComplete: @escaping (OnboardingCompletionDestination?) -> Void) -> BandzOnboardingCoordinator {
        let userDataManager = safeResolve(UserDataManager.self, context: "CoordinatorsRegistrar.createOnboardingCoordinator")
        let authService = safeResolve(FirebaseAuthService.self, context: "CoordinatorsRegistrar.createOnboardingCoordinator")
        let genreService = safeResolve(GenreService.self, context: "CoordinatorsRegistrar.createOnboardingCoordinator")
        let placeService = safeResolve(PlaceService.self, context: "CoordinatorsRegistrar.createOnboardingCoordinator")

        assert(Thread.isMainThread, "OnboardingCoordinator creation must be on main thread")
        return MainActor.assumeIsolated {
            BandzOnboardingCoordinator(
                userDataManager: userDataManager,
                authService: authService,
                genreService: genreService,
                placeService: placeService,
                onComplete: onComplete
            )
        }
    }
}
