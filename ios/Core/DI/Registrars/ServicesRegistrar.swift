import Foundation

/// Registrar for application services (Auth, Firestore, Domain services, etc.)
final class ServicesRegistrar: BaseRegistrar {

    func register() {
        registerAuthServices()
        registerFirestoreServices()
        registerDomainServices()
        registerLocationServices()
        registerHomeServices()
        registerNotificationServices()
        registerNetworkingServices()
    }

    // MARK: - Auth Services

    private func registerAuthServices() {
        container.register(FirebaseAuthService.self, scope: .singleton) {
            let spotifyAuthHelper = try? self.container.resolve(SpotifyAuthHelper.self)
            return MainActor.assumeIsolated { FirebaseAuthService(spotifyAuthHelper: spotifyAuthHelper) }
        }

        container.register(AuthServiceProtocol.self, scope: .singleton) {
            // Resolve the already-registered singleton — never create a second instance
            self.container.resolveSafe(FirebaseAuthService.self)
        }
    }

    // MARK: - Firestore Services

    private func registerFirestoreServices() {
        // Core Firestore services
        container.register(FirestoreUserService.self, scope: .singleton) { FirestoreUserService() }
        container.register(FirestoreService.self, scope: .singleton) { FirestoreService() }

        // Domain-specific Firestore services
        container.register(FirestoreEventService.self, scope: .singleton) { FirestoreEventService() }
        container.register(FirestorePlaceService.self, scope: .singleton) { FirestorePlaceService() }
        container.register(FirestoreArtistService.self, scope: .singleton) { FirestoreArtistService() }
        container.register(FirestoreContentService.self, scope: .singleton) { FirestoreContentService() }
        container.register(FirestoreDeviceTokenService.self, scope: .singleton) { FirestoreDeviceTokenService() }
        container.register(FirestoreNotificationService.self, scope: .singleton) { FirestoreNotificationService() }
        container.register(FirestoreStreamingDataService.self, scope: .singleton) { FirestoreStreamingDataService() }
    }

    // MARK: - Domain Services

    private func registerDomainServices() {
        // PlaceService
        container.register(PlaceService.self, scope: .singleton) {
            let firestoreService = self.safeResolve(FirestoreService.self, context: "ServicesRegistrar.PlaceService")
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "ServicesRegistrar.PlaceService")
            return self.mainActorIsolated {
                PlaceService(firestoreService: firestoreService, logger: logger)
            }
        }

        // GenreService
        container.register(GenreService.self, scope: .singleton) {
            let firestoreService = self.safeResolve(FirestoreService.self, context: "ServicesRegistrar.GenreService")
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "ServicesRegistrar.GenreService")
            return self.mainActorIsolated {
                GenreService(
                    firestoreService: firestoreService,
                    logger: logger,
                    cacheExpirationHours: 24.0
                )
            }
        }

        // GeolocationService
        container.register(GeolocationService.self, scope: .singleton) {
            GeolocationService(logger: Logger.shared)
        }

        // ImageService
        container.register(ImageService.self, scope: .singleton) {
            ImageService(logger: Logger.shared)
        }

        // HomeBannerService
        container.register(HomeBannerService.self, scope: .singleton) {
            let firestoreService = self.safeResolve(FirestoreService.self, context: "ServicesRegistrar.HomeBannerService")
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "ServicesRegistrar.HomeBannerService")
            return self.mainActorIsolated {
                HomeBannerService(
                    firestoreService: firestoreService,
                    logger: logger,
                    cacheExpirationHours: 4.0
                )
            }
        }

        // UserPreferencesCache
        container.register(UserPreferencesCache.self, scope: .singleton) {
            UserPreferencesCache()
        }
    }

    // MARK: - Location Services

    private func registerLocationServices() {
        container.register(LocationManager.self, scope: .singleton) {
            return self.mainActorIsolated { LocationManager() }
        }
    }

    // MARK: - Home Services

    private func registerHomeServices() {
        // FeedSessionTracker (cross-session state persistence)
        container.register(FeedSessionTracker.self, scope: .singleton) {
            return self.mainActorIsolated { FeedSessionTracker() }
        }

        // FeedAssemblyPipeline (scoring + assembly engine)
        container.register(FeedAssemblyPipeline.self, scope: .singleton) {
            let imageService = self.safeResolve(ImageService.self, context: "ServicesRegistrar.FeedAssemblyPipeline")
            let sessionTracker = self.safeResolve(FeedSessionTracker.self, context: "ServicesRegistrar.FeedAssemblyPipeline")
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "ServicesRegistrar.FeedAssemblyPipeline")
            return self.mainActorIsolated {
                FeedAssemblyPipeline(
                    cache: FeedCache(),
                    sessionTracker: sessionTracker,
                    imageService: imageService,
                    logger: logger
                )
            }
        }

        // HomeEventsService (data loading + orchestration)
        container.register(HomeEventsService.self, scope: .singleton) {
            let firestoreService = self.safeResolve(FirestoreService.self, context: "ServicesRegistrar.HomeEventsService")
            let imageService = self.safeResolve(ImageService.self, context: "ServicesRegistrar.HomeEventsService")
            let geolocationService = self.safeResolve(GeolocationService.self, context: "ServicesRegistrar.HomeEventsService")
            let userDataManager = self.safeResolve(UserDataManager.self, context: "ServicesRegistrar.HomeEventsService")
            let userPrefsCache = self.safeResolve(UserPreferencesCache.self, context: "ServicesRegistrar.HomeEventsService")
            let firestoreUserDataService = FirestoreUserDataService()
            let locationManager = self.safeResolve(LocationManager.self, context: "ServicesRegistrar.HomeEventsService")
            let feedPipeline = self.safeResolve(FeedAssemblyPipeline.self, context: "ServicesRegistrar.HomeEventsService")
            let genreService: GenreService? = try? DIContainer.shared.resolve(GenreService.self)
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "ServicesRegistrar.HomeEventsService")
            return self.mainActorIsolated {
                HomeEventsService(
                    firestoreService: firestoreService,
                    imageService: imageService,
                    geolocationService: geolocationService,
                    userDataManager: userDataManager,
                    logger: logger,
                    userPreferencesCache: userPrefsCache,
                    userDataService: firestoreUserDataService,
                    locationManager: locationManager,
                    feedPipeline: feedPipeline,
                    genreService: genreService
                )
            }
        }
    }

    // MARK: - Notification Services

    private func registerNotificationServices() {
        container.register(NotificationsStore.self, scope: .singleton) {
            let firestoreService = self.safeResolve(FirestoreService.self, context: "ServicesRegistrar.NotificationsStore")
            let userDataManager = self.safeResolve(UserDataManager.self, context: "ServicesRegistrar.NotificationsStore")
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "ServicesRegistrar.NotificationsStore")
            return self.mainActorIsolated {
                NotificationsStore(
                    firestoreService: firestoreService,
                    userDataManager: userDataManager,
                    logger: logger
                )
            }
        }

        container.register(NotificationRouter.self, scope: .singleton) {
            let notificationsStore = self.safeResolve(NotificationsStore.self, context: "ServicesRegistrar.NotificationRouter")
            let firestoreService = self.safeResolve(FirestoreService.self, context: "ServicesRegistrar.NotificationRouter")
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "ServicesRegistrar.NotificationRouter")
            let pushManager = self.safeResolve(PushNotificationManager.self, context: "ServicesRegistrar.NotificationRouter")
            return self.mainActorIsolated {
                let router = NotificationRouter(
                    notificationsStore: notificationsStore,
                    firestoreService: firestoreService,
                    logger: logger
                )
                router.register(pushManager: pushManager)
                return router
            }
        }

        container.register(PushTokenService.self, scope: .singleton) {
            let firestoreService = self.safeResolve(FirestoreService.self, context: "ServicesRegistrar.PushTokenService")
            let userDataManager = self.safeResolve(UserDataManager.self, context: "ServicesRegistrar.PushTokenService")
            let logger = self.safeResolveOrDefault(Logger.self, default: Logger.shared, context: "ServicesRegistrar.PushTokenService")
            let pushManager = self.safeResolve(PushNotificationManager.self, context: "ServicesRegistrar.PushTokenService")
            return self.mainActorIsolated {
                PushTokenService(
                    firestoreService: firestoreService,
                    userDataManager: userDataManager,
                    logger: logger,
                    pushNotificationManager: pushManager
                )
            }
        }
    }

    // MARK: - Networking Services

    private func registerNetworkingServices() {
        container.register(NetworkClient.self, scope: .transient) { NetworkClient() }
    }
}
