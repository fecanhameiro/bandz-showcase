import Foundation
import FirebaseCrashlytics

/// Main service responsible for registering all dependencies with the DIContainer.
///
/// This class orchestrates modular registrars for better organization and maintainability.
/// Each registrar handles a specific domain of dependencies.
///
/// ## Thread Safety
/// All registration happens during app startup from the main thread.
/// This is guaranteed by iOS framework behavior in AppDelegate.application(_:didFinishLaunchingWithOptions:).
///
/// ## Registrar Organization
/// - `CoreManagersRegistrar`: Firebase managers, app managers, Logger, UserDataManager
/// - `InfrastructureServicesRegistrar`: Security, Connectivity, Localization
/// - `StreamingServicesRegistrar`: Spotify and Apple Music services
/// - `ServicesRegistrar`: Auth, Firestore, Domain services
/// - `ViewModelsRegistrar`: ViewModels
/// - `CoordinatorsRegistrar`: Navigation coordinators
final class DependencyRegistrar {
    private let container: DIContainer

    // Modular registrars
    private lazy var coreManagersRegistrar = CoreManagersRegistrar(container: container)
    private lazy var infrastructureServicesRegistrar = InfrastructureServicesRegistrar(container: container)
    private lazy var streamingServicesRegistrar = StreamingServicesRegistrar(container: container)
    private lazy var servicesRegistrar = ServicesRegistrar(container: container)
    private lazy var viewModelsRegistrar = ViewModelsRegistrar(container: container)
    private lazy var coordinatorsRegistrar = CoordinatorsRegistrar(container: container)

    /// Initialize the registrar with a container
    init(container: DIContainer = DIContainer.shared) {
        self.container = container
    }

    /// Register all application dependencies in the correct order.
    ///
    /// Order matters! Dependencies must be registered before they are resolved.
    /// The registration order follows the dependency graph:
    /// 1. Core managers (no dependencies)
    /// 2. Infrastructure (security needed by streaming)
    /// 3. Streaming services (needed by auth services)
    /// 4. Services (depends on managers, infrastructure)
    /// 5. ViewModels (depends on services)
    /// 6. Coordinators (depends on services, viewmodels)
    func registerAllDependencies() {
        coreManagersRegistrar.register()
        infrastructureServicesRegistrar.register()
        streamingServicesRegistrar.register()
        servicesRegistrar.register()
        viewModelsRegistrar.register()
        coordinatorsRegistrar.register()
    }

    // MARK: - Factory Methods (Delegated to Coordinators Registrar)

    /// Factory method for creating a coordinator with properly injected dependencies
    func coordinatorFactory<T>(_ type: T.Type) -> T {
        coordinatorsRegistrar.coordinatorFactory(type)
    }

    /// Factory method for creating OnboardingCoordinator with proper dependencies
    func createOnboardingCoordinator(onComplete: @escaping (OnboardingCompletionDestination?) -> Void) -> BandzOnboardingCoordinator {
        coordinatorsRegistrar.createOnboardingCoordinator(onComplete: onComplete)
    }
}
