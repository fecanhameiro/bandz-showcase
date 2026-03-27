import Foundation
import FirebaseCrashlytics

/// Registrar for core manager dependencies (Firebase managers, app managers, Logger, UserDataManager)
final class CoreManagersRegistrar: BaseRegistrar {

    func register() {
        registerFirebaseManagers()
        registerAppManagers()
        registerLogger()
        registerUserDataManager()
    }

    // MARK: - Firebase Managers

    private func registerFirebaseManagers() {
        container.register(AnalyticsManager.self, scope: .singleton) { AnalyticsManager.shared }
        container.register(RemoteConfigManager.self, scope: .singleton) { RemoteConfigManager.shared }
        container.register(CrashlyticsManager.self, scope: .singleton) { CrashlyticsManager.shared }
        container.register(PushNotificationManager.self, scope: .singleton) { PushNotificationManager.shared }
    }

    // MARK: - App Managers

    private func registerAppManagers() {
        container.register(ThemeManager.self, scope: .singleton) { self.mainActorIsolated { ThemeManager.shared } }
        container.register(UserManager.self, scope: .singleton) { self.mainActorIsolated { UserManager.shared } }
        container.register(FirebaseManager.self, scope: .singleton) { FirebaseManager.shared }
    }

    // MARK: - Logger

    private func registerLogger() {
        container.register(Logger.self, scope: .singleton) { Logger.shared }
        configureLoggingDestinationsIfNeeded()
    }

    private static var hasConfiguredLoggerDestinations = false

    private func configureLoggingDestinationsIfNeeded() {
        guard !Self.hasConfiguredLoggerDestinations else { return }

        let destination = FirestoreLogDestination(minimumLogLevel: .info)
        Logger.shared.addDestination(destination)
        Self.hasConfiguredLoggerDestinations = true
    }

    // MARK: - UserDataManager

    private func registerUserDataManager() {
        container.register(UserDataManager.self, scope: .singleton) {
            let firestoreUserDataService = FirestoreUserDataService()
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "CoreManagersRegistrar.UserDataManager")
            let persistenceAdapter = FirestoreUserDataServiceAdapter(firestoreService: firestoreUserDataService, logger: logger)
            return self.mainActorIsolated {
                UserDataManager(
                    persistenceService: persistenceAdapter,
                    logger: logger
                )
            }
        }
    }
}
