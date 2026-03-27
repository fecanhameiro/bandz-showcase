import Foundation

/// Registrar for streaming services (Spotify and Apple Music)
final class StreamingServicesRegistrar: BaseRegistrar {

    func register() {
        registerSpotifyServices()
        registerAppleMusicServices()
    }

    // MARK: - Spotify Services

    private func registerSpotifyServices() {
        // SpotifyAuthHelper - singleton for consistent token management
        container.register(SpotifyAuthHelper.self, scope: .singleton) {
            let secureStorage = self.safeResolve(SecureStorageProtocol.self, context: "StreamingServicesRegistrar.SpotifyAuthHelper")
            return self.mainActorIsolated {
                SpotifyAuthHelper(secureStorage: secureStorage)
            }
        }

        // SpotifyAPIService - transient for flexibility
        container.register(SpotifyAPIServiceProtocol.self, scope: .transient) {
            let spotifyAuthHelper = self.safeResolve(SpotifyAuthHelper.self, context: "StreamingServicesRegistrar.SpotifyAPIService")
            return self.mainActorIsolated {
                SpotifyAPIService(spotifyAuthHelper: spotifyAuthHelper)
            }
        }

        // SpotifyDataProcessor - singleton (stateless)
        container.register(SpotifyDataProcessorProtocol.self, scope: .singleton) {
            SpotifyDataProcessor()
        }

        // SpotifyIntegrationService - transient for specific flows
        container.register(SpotifyIntegrationServiceProtocol.self, scope: .transient) {
            let apiService = self.safeResolve(SpotifyAPIServiceProtocol.self, context: "StreamingServicesRegistrar.SpotifyIntegrationService")
            let dataProcessor = self.safeResolve(SpotifyDataProcessorProtocol.self, context: "StreamingServicesRegistrar.SpotifyIntegrationService")
            let firestoreService = self.safeResolve(FirestoreService.self, context: "StreamingServicesRegistrar.SpotifyIntegrationService")
            let userManager = self.safeResolveOrDefault(UserManager.self, default: MainActor.assumeIsolated { UserManager.shared }, context: "StreamingServicesRegistrar.SpotifyIntegrationService")
            let firebaseAuthService = self.safeResolve(FirebaseAuthService.self, context: "StreamingServicesRegistrar.SpotifyIntegrationService")
            let spotifyAuthHelper = self.safeResolve(SpotifyAuthHelper.self, context: "StreamingServicesRegistrar.SpotifyIntegrationService")

            return self.mainActorIsolated {
                SpotifyIntegrationService(
                    apiService: apiService,
                    dataProcessor: dataProcessor,
                    firestoreService: firestoreService,
                    userManager: userManager,
                    firebaseAuthService: firebaseAuthService,
                    spotifyAuthHelper: spotifyAuthHelper
                )
            }
        }
    }

    // MARK: - Apple Music Services

    private func registerAppleMusicServices() {
        container.register(AppleMusicAuthHelper.self, scope: .singleton) {
            let secureStorage = self.safeResolve(SecureStorageProtocol.self, context: "StreamingServicesRegistrar.AppleMusicAuthHelper")
            return self.mainActorIsolated {
                AppleMusicAuthHelper(secureStorage: secureStorage)
            }
        }

        // Native API Service
        container.register(AppleMusicNativeAPIServiceProtocol.self, scope: .transient) {
            let authHelper = self.safeResolve(AppleMusicAuthHelper.self, context: "StreamingServicesRegistrar.AppleMusicNativeAPIService")
            return self.mainActorIsolated {
                AppleMusicNativeAPIService(authHelper: authHelper)
            }
        }

        // Native Integration Service
        container.register(AppleMusicIntegrationServiceProtocol.self, scope: .transient) {
            let authHelper = self.safeResolve(AppleMusicAuthHelper.self, context: "StreamingServicesRegistrar.AppleMusicNativeIntegrationService")
            let nativeAPIService = self.safeResolve(AppleMusicNativeAPIServiceProtocol.self, context: "StreamingServicesRegistrar.AppleMusicNativeIntegrationService")
            let firestoreService = self.safeResolve(FirestoreService.self, context: "StreamingServicesRegistrar.AppleMusicNativeIntegrationService")
            let userDataManager = self.safeResolve(UserDataManager.self, context: "StreamingServicesRegistrar.AppleMusicNativeIntegrationService")
            return self.mainActorIsolated {
                AppleMusicNativeIntegrationService(
                    authHelper: authHelper,
                    nativeAPIService: nativeAPIService,
                    firestoreService: firestoreService,
                    userDataManager: userDataManager
                )
            }
        }
    }
}
