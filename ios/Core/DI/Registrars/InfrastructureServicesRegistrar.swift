import Foundation

/// Registrar for infrastructure services (Security, Connectivity, Localization)
final class InfrastructureServicesRegistrar: BaseRegistrar {

    func register() {
        registerSecurityServices()
        registerConnectivityServices()
        registerLocalizationServices()
    }

    // MARK: - Security Services

    private func registerSecurityServices() {
        container.register(SecurityProtocol.self, scope: .singleton) { SecurityManager.shared }
        container.register(SecureStorageProtocol.self, scope: .singleton) {
            SecureStorage(service: "com.bandz.security")
        }
        container.register(CryptographyProtocol.self, scope: .singleton) { Cryptography.shared }
        container.register(CertificatePinningProtocol.self, scope: .singleton) { CertificatePinning.shared }
    }

    // MARK: - Connectivity Services

    private func registerConnectivityServices() {
        container.register((any ConnectivityProtocol).self, scope: .singleton) {
            MainActor.assumeIsolated { ConnectivityManager.shared }
        }
    }

    // MARK: - Localization Services

    private func registerLocalizationServices() {
        container.register(LocalizationProtocol.self, scope: .singleton) { LocalizationManager.shared }
    }
}
