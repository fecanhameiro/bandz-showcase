import Foundation
import FirebaseCrashlytics

/// Base class for dependency registrars with common utility methods.
///
/// THREAD SAFETY: All registrars use MainActor.assumeIsolated for @MainActor classes.
/// This is safe because:
/// 1. Registration happens during app startup in AppDelegate.application(_:didFinishLaunchingWithOptions:)
/// 2. That method executes on the main thread by iOS framework guarantee
/// 3. We add assert(Thread.isMainThread) to verify this assumption in debug builds
/// 4. MainActor.assumeIsolated is the recommended pattern for initialization code
class BaseRegistrar {
    let container: DIContainer

    init(container: DIContainer = DIContainer.shared) {
        self.container = container
    }

    // MARK: - Safe Resolution Utilities

    /// Safely resolves a dependency, providing a descriptive error if resolution fails.
    /// In DEBUG builds, triggers assertionFailure. In RELEASE, logs to Crashlytics and crashes with context.
    func safeResolve<T>(_ type: T.Type, context: String) -> T {
        do {
            return try container.resolve(type)
        } catch {
            let message = "Failed to resolve \(type) in \(context). Ensure dependency is registered before use. Error: \(error)"
            #if DEBUG
            assertionFailure(message)
            #endif
            CrashlyticsManager.shared.recordError(
                NSError(domain: "DependencyRegistrar", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            )
            fatalError(message)
        }
    }

    /// Safely resolves a dependency with a fallback value if resolution fails.
    func safeResolveOrDefault<T>(_ type: T.Type, default fallback: T, context: String) -> T {
        do {
            return try container.resolve(type)
        } catch {
            Logger.shared.warning("Failed to resolve \(type) in \(context), using fallback. Error: \(error)", context: "DependencyRegistrar")
            return fallback
        }
    }

    // MARK: - MainActor Isolation Helper

    /// Executes a closure on the MainActor, validating main thread in all builds.
    /// Use this for creating @MainActor classes during DI registration.
    func mainActorIsolated<T>(_ closure: @MainActor () -> T) -> T {
        precondition(Thread.isMainThread, "DependencyRegistrar must be called from main thread")
        return MainActor.assumeIsolated(closure)
    }
}
