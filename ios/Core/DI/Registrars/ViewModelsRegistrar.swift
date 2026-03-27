import Foundation

/// Registrar for ViewModel dependencies
final class ViewModelsRegistrar: BaseRegistrar {

    func register() {
        registerAuthViewModels()
        registerHomeViewModels()
    }

    // MARK: - Auth ViewModels

    private func registerAuthViewModels() {
        // LoginViewModel - transient as tied to view instances
        container.register(LoginViewModel.self, scope: .transient) {
            let authService = self.safeResolve(AuthServiceProtocol.self, context: "ViewModelsRegistrar.LoginViewModel")
            return self.mainActorIsolated {
                LoginViewModel(authService: authService)
            }
        }

        // SignupViewModel - transient as tied to view instances
        container.register(SignupViewModel.self, scope: .transient) {
            let authService = self.safeResolve(AuthServiceProtocol.self, context: "ViewModelsRegistrar.SignupViewModel")
            return self.mainActorIsolated {
                SignupViewModel(authService: authService)
            }
        }
    }

    // MARK: - Home ViewModels

    private func registerHomeViewModels() {
        // HomeViewModel - singleton so reset() on logout operates on the actual instance
        container.register(HomeViewModel.self, scope: .singleton) {
            return self.mainActorIsolated {
                HomeViewModel()
            }
        }
    }
}
