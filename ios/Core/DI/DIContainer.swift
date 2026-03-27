import Foundation

/// The scope of a registered service in the container
enum DIScope {
    /// A singleton instance that is created once and reused
    case singleton
    /// A new instance is created each time the service is resolved
    case transient
}

/// A dependency injection container for the Bandz application.
/// This container manages the registration and resolution of services.
/// Thread-safe implementation using NSLock for concurrent access.
final class DIContainer {

    /// The shared singleton instance of the container
    static let shared = DIContainer()

    /// Private initializer to enforce singleton pattern
    private init() {}

    /// Recursive lock — allows the same thread to re-enter during singleton
    /// resolution when a factory resolves other dependencies.
    private let lock = NSRecursiveLock()

    /// Dictionary to store factory closures for services.
    /// Uses ObjectIdentifier as key to avoid name collisions across modules.
    private var factories: [ObjectIdentifier: Any] = [:]

    /// Dictionary to store singleton instances
    private var singletons: [ObjectIdentifier: Any] = [:]

    /// Dictionary to store service scopes
    private var scopes: [ObjectIdentifier: DIScope] = [:]

    /// Thread-safe wrapper for synchronized access
    private func synchronized<T>(_ block: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return block()
    }

    /// Thread-safe wrapper for synchronized access with throwing support
    private func synchronizedThrowing<T>(_ block: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try block()
    }
    
    /// Register a service with the container
    /// - Parameters:
    ///   - type: The type of service to register
    ///   - scope: The scope of the service (singleton or transient)
    ///   - factory: A closure that creates an instance of the service
    func register<T>(_ type: T.Type, scope: DIScope = .transient, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        synchronized {
            factories[key] = factory
            scopes[key] = scope

            // If it's a singleton scope, remove any existing instance so it will be recreated on next resolve
            if scope == .singleton {
                singletons.removeValue(forKey: key)
            }
        }
    }
    
    /// Resolve a service from the container
    /// - Parameter type: The type of service to resolve
    /// - Returns: An instance of the requested service
    /// - Throws: DIError.serviceNotRegistered if the service is not registered
    func resolve<T>(_ type: T.Type) throws -> T {
        let key = ObjectIdentifier(type)

        return try synchronizedThrowing {
            guard let factory = factories[key] as? () -> T else {
                throw DIError.serviceNotRegistered(type: String(describing: type))
            }
            let scope = scopes[key] ?? .transient

            switch scope {
            case .singleton:
                if let existing = singletons[key] as? T {
                    return existing
                }
                // Safe to call factory inside lock — NSRecursiveLock allows
                // re-entry when the factory resolves other dependencies.
                let instance = factory()
                singletons[key] = instance
                return instance
            case .transient:
                return factory()
            }
        }
    }
    
    /// Resolve a service from the container returning a Result
    /// - Parameter type: The type of service to resolve
    /// - Returns: Result containing the service instance or an error
    func resolveResult<T>(_ type: T.Type) -> Result<T, DIError> {
        do {
            return .success(try resolve(type))
        } catch let error as DIError {
            return .failure(error)
        } catch {
            return .failure(.serviceNotRegistered(type: String(describing: type)))
        }
    }

    /// Resolve a service from the container (non-throwing version)
    /// - Parameter type: The type of service to resolve
    /// - Returns: An instance of the requested service
    /// - Note: This method will assert in DEBUG and crash with context in RELEASE if the service is not registered
    func resolveSafe<T>(_ type: T.Type) -> T {
        do {
            return try resolve(type)
        } catch {
            let errorMessage = "DIContainer: Failed to resolve \(String(describing: type)). Error: \(error). Ensure the dependency is registered in DependencyRegistrar."
            // Log the error for production debugging
            Logger.shared.error("DIContainer resolution failed", metadata: [
                "feature": "DI",
                "tags": ["DI", "Error"],
                "type": String(describing: type),
                "error": error.localizedDescription
            ], context: "DIContainer")
            CrashlyticsManager.shared.recordError(
                NSError(domain: "DIContainer", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            )
            #if DEBUG
            fatalError(errorMessage)
            #else
            // In production, crash with full context for diagnostics
            preconditionFailure(errorMessage)
            #endif
        }
    }
    
    /// Get a service from the container with a default fallback if not registered
    /// - Parameters:
    ///   - type: The type of service to resolve
    ///   - default: A default implementation to use if the service is not registered
    /// - Returns: The registered service or the default implementation
    func resolveOrDefault<T>(_ type: T.Type, default: @autoclosure () -> T) -> T {
        do {
            return try resolve(type)
        } catch {
            return `default`()
        }
    }
    
    /// Check if a service is registered with the container
    /// - Parameter type: The type of service to check
    /// - Returns: True if the service is registered, false otherwise
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = ObjectIdentifier(type)
        return synchronized { factories[key] != nil }
    }

    /// Remove all registered services from the container
    func reset() {
        synchronized {
            factories.removeAll()
            singletons.removeAll()
            scopes.removeAll()
        }
    }
}

/// Errors that can be thrown by the DIContainer
enum DIError: Error, LocalizedError {
    case serviceNotRegistered(type: String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let type):
            return "Service of type \(type) is not registered with the container"
        }
    }
}

/// A property wrapper for injecting dependencies
/// - Note: Uses assertionFailure in DEBUG builds for better error detection during development
@propertyWrapper
struct Inject<T> {
    let wrappedValue: T

    init() {
        do {
            self.wrappedValue = try DIContainer.shared.resolve(T.self)
        } catch {
            let errorMessage = "@Inject: Failed to resolve \(String(describing: T.self)). Error: \(error). Ensure the dependency is registered in DependencyRegistrar before use."
            Logger.shared.error("@Inject resolution failed", metadata: [
                "feature": "DI",
                "tags": ["DI", "Error"],
                "type": String(describing: T.self),
                "error": error.localizedDescription
            ], context: "DIContainer.Inject")
            CrashlyticsManager.shared.recordError(
                NSError(domain: "DIContainer.Inject", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            )
            #if DEBUG
            fatalError(errorMessage)
            #else
            // In production, crash with full context for diagnostics
            preconditionFailure(errorMessage)
            #endif
        }
    }
}

/// A property wrapper for injecting dependencies with a default implementation
@propertyWrapper
struct InjectOrDefault<T> {
    let wrappedValue: T
    
    init(default: @autoclosure () -> T) {
        self.wrappedValue = DIContainer.shared.resolveOrDefault(T.self, default: `default`())
    }
}

/// Protocol for objects that need to be configured with dependencies
protocol DIContainerSettable {
    /// Set the DIContainer for this object
    func setDIContainer(_ container: DIContainer)
}

// MARK: - MainAppView Dependencies Factory

extension DIContainer {
    /// Container for MainAppView critical dependencies
    struct MainAppDependencies {
        let coordinator: AppCoordinator
        let notificationsStore: NotificationsStore
        let notificationRouter: NotificationRouter
    }

    /// Resolves all critical dependencies for MainAppView in a single call
    /// - Returns: MainAppDependencies containing all required dependencies
    /// - Throws: DIError if any dependency is not registered
    func resolveMainAppDependencies() throws -> MainAppDependencies {
        return MainAppDependencies(
            coordinator: try resolve(AppCoordinator.self),
            notificationsStore: try resolve(NotificationsStore.self),
            notificationRouter: try resolve(NotificationRouter.self)
        )
    }

    /// Creates an OnboardingCoordinator with properly injected dependencies.
    /// Resolves dependencies directly from the container without creating a full DependencyRegistrar.
    @MainActor
    func createOnboardingCoordinator(onComplete: @escaping (OnboardingCompletionDestination?) -> Void) -> BandzOnboardingCoordinator {
        BandzOnboardingCoordinator(
            userDataManager: resolveSafe(UserDataManager.self),
            authService: resolveSafe(FirebaseAuthService.self),
            genreService: resolveSafe(GenreService.self),
            placeService: resolveSafe(PlaceService.self),
            onComplete: onComplete
        )
    }
}