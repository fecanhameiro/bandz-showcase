import Foundation

// MARK: - AuthMethod Enum

/// Métodos de autenticação disponíveis
enum AuthMethod: String, Codable, CaseIterable {
    case anonymous = "anonymous"
    case google = "google"
    case facebook = "facebook"
    case apple = "apple"
    case phone = "phone"
    case email = "email"
    case spotify = "spotify"

    var displayName: String {
        switch self {
        case .anonymous: return "Anônimo"
        case .google: return "Google"
        case .facebook: return "Facebook"
        case .apple: return "Apple"
        case .phone: return "Telefone"
        case .email: return "Email"
        case .spotify: return "Spotify"
        }
    }
}
