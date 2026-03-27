import Foundation
import FirebaseAuth

/// Handles the finalization logic for different authentication methods during onboarding
enum OnboardingFinalizer {

    /// Finalizes onboarding user data in-memory (no Firestore persistence).
    /// Persistence is deferred to the completion screen via coordinator.persistOnboardingData().
    /// - Parameters:
    ///   - authMethod: The authentication method used (google, facebook, spotify, phone, or nil for anonymous)
    ///   - userDataManager: The user data manager to update
    ///   - authService: Optional auth service to check for orphaned anonymous UIDs
    ///   - requiresFirebaseAuth: Whether Firebase authentication is required (false for anonymous)
    /// - Returns: The finalized Firebase user, if any
    @MainActor
    static func finalizeUserData(
        authMethod: AuthMethod?,
        userDataManager: UserDataManager,
        authService: AuthServiceProtocol? = nil,
        requiresFirebaseAuth: Bool = true
    ) async throws -> FirebaseAuth.User? {
        let methodName = authMethod?.rawValue ?? "anonymous"

        Logger.shared.debug("finalize(\(methodName)) started", context: "OnboardingFinalizer")

        var firebaseUser: FirebaseAuth.User?

        if requiresFirebaseAuth {
            guard let user = Auth.auth().currentUser else {
                throw OnboardingFinalizationError.userNotAuthenticated
            }
            firebaseUser = user

            Logger.shared.info("Using authenticated user - UID: \(user.uid)", context: "OnboardingFinalizer")

            if let method = authMethod {
                try userDataManager.finalizeOnboarding(with: user, authMethod: method)
            } else {
                try userDataManager.finalizeOnboarding(with: user)
            }
        }

        Logger.shared.info("UserData finalized in-memory with \(methodName) info", context: "OnboardingFinalizer")

        // Clear orphaned anonymous UID tracking (cleanup deferred to Cloud Function)
        if authService?.orphanedAnonymousUID != nil {
            authService?.clearOrphanedAnonymousUID()
        }

        return firebaseUser
    }
}

// MARK: - Error Types

enum OnboardingFinalizationError: LocalizedError {
    case userNotAuthenticated
    case timeout

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .timeout:
            return "Onboarding finalization timed out"
        }
    }
}
