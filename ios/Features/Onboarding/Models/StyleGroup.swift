//
//  StyleGroup.swift
//  Bandz
//
//  Created by Claude Code on 23/01/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore


// MARK: - StyleGroupTranslation

struct StyleGroupTranslation: Codable, Equatable, Hashable, Sendable {
    let name: String
    let description: String?
}

// MARK: - StyleGroup Model

/// Modelo de dados para grupos de estilos musicais carregados da Firestore
/// Collection: BR_bandz_style_groups
struct StyleGroup: Codable, Equatable, Hashable, Identifiable, Sendable {

    // MARK: - Required Properties

    /// ID semântico do grupo (ex: "rock_group")
    let id: String

    /// Nome do grupo (ex: "Rock")
    let name: String

    /// Gênero principal do grupo (ex: "Rock")
    let mainGenre: String

    /// Cor hexadecimal do grupo (ex: "#E53935")
    let color: String

    /// Nome do ícone legado (ex: "rock_icon")
    let icon: String

    /// Lista de gêneros inclusos no grupo (max 3)
    let genres: [String]

    /// Strings legadas de match
    let styleStrings: [String]

    // MARK: - Optional Properties

    /// Data de criação
    let createdAt: Date?

    /// Descrição do grupo
    let description: String?

    /// Default true
    let active: Bool?

    /// Ordem de exibição (por popularidade BR)
    let order: Int?

    /// URL da imagem no Firebase Storage
    let imageUrl: String?

    /// Traduções (pt-BR, en, es)
    let translations: [String: StyleGroupTranslation]?

    /// Genre affinity weights to other styleGroups (e.g., {"alternativo_group": 0.8, "blues_group": 0.5}).
    /// Used by the feed algorithm's GenreAffinityMap for cross-genre scoring.
    let affinities: [String: Double]?

    /// Estado de seleção para UI (não persistido)
    var isSelected: Bool = false

    // MARK: - Initialization

    /// Inicializador principal
    init(
        id: String,
        name: String,
        mainGenre: String,
        color: String,
        icon: String,
        genres: [String],
        styleStrings: [String],
        createdAt: Date? = nil,
        description: String? = nil,
        active: Bool? = nil,
        order: Int? = nil,
        imageUrl: String? = nil,
        translations: [String: StyleGroupTranslation]? = nil,
        affinities: [String: Double]? = nil,
        isSelected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.mainGenre = mainGenre
        self.color = color
        self.icon = icon
        self.genres = genres
        self.styleStrings = styleStrings
        self.createdAt = createdAt
        self.description = description
        self.active = active
        self.order = order
        self.imageUrl = imageUrl
        self.translations = translations
        self.affinities = affinities
        self.isSelected = isSelected
    }
    
    // MARK: - Computed Properties
    
    /// Converte a cor hex para SwiftUI Color
    /// Fallback para cor primária se conversão falhar
    var uiColor: Color {
        return Color(hex: color) ?? ColorSystem.Brand.primary
    }
    
    /// Cor com opacidade reduzida para backgrounds
    var backgroundColorLight: Color {
        return uiColor.opacity(0.1)
    }
    
    /// Cor com opacidade média para bordas
    var borderColor: Color {
        return uiColor.opacity(0.3)
    }

    /// Formatted subtitle from sub-genres (excludes mainGenre to avoid duplication)
    var subtitleText: String {
        let filtered = genres.first == mainGenre ? Array(genres.dropFirst()) : genres
        return !filtered.isEmpty ? filtered.joined(separator: " • ") : mainGenre
    }
    
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, name, mainGenre, color, icon, genres, styleStrings
        case createdAt, description, active, order, imageUrl, translations, affinities
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedId = try container.decode(String.self, forKey: .id)
        guard !decodedId.isEmpty else {
            throw StyleGroupError.invalidData(field: "id", reason: "ID cannot be empty")
        }
        self.id = decodedId

        let decodedName = try container.decode(String.self, forKey: .name)
        guard !decodedName.isEmpty else {
            throw StyleGroupError.invalidData(field: "name", reason: "Name cannot be empty")
        }
        self.name = decodedName

        let decodedMainGenre = try container.decode(String.self, forKey: .mainGenre)
        guard !decodedMainGenre.isEmpty else {
            throw StyleGroupError.invalidData(field: "mainGenre", reason: "Main genre cannot be empty")
        }
        self.mainGenre = decodedMainGenre

        let decodedColor = try container.decode(String.self, forKey: .color)
        guard !decodedColor.isEmpty else {
            throw StyleGroupError.invalidData(field: "color", reason: "Color cannot be empty")
        }
        self.color = decodedColor

        let decodedIcon = try container.decode(String.self, forKey: .icon)
        guard !decodedIcon.isEmpty else {
            throw StyleGroupError.invalidData(field: "icon", reason: "Icon cannot be empty")
        }
        self.icon = decodedIcon

        let decodedGenres = try container.decode([String].self, forKey: .genres)
        guard !decodedGenres.isEmpty else {
            throw StyleGroupError.invalidData(field: "genres", reason: "Genres array cannot be empty")
        }
        self.genres = decodedGenres.filter { !$0.isEmpty }

        self.styleStrings = try container.decodeIfPresent([String].self, forKey: .styleStrings)?
            .filter { !$0.isEmpty } ?? []

        // Optional fields
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.active = try container.decodeIfPresent(Bool.self, forKey: .active)
        self.order = try container.decodeIfPresent(Int.self, forKey: .order)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.translations = try container.decodeIfPresent([String: StyleGroupTranslation].self, forKey: .translations)
        self.affinities = try container.decodeIfPresent([String: Double].self, forKey: .affinities)

        self.isSelected = false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(mainGenre, forKey: .mainGenre)
        try container.encode(color, forKey: .color)
        try container.encode(icon, forKey: .icon)
        try container.encode(genres, forKey: .genres)
        try container.encode(styleStrings, forKey: .styleStrings)

        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(active, forKey: .active)
        try container.encodeIfPresent(order, forKey: .order)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(translations, forKey: .translations)
        try container.encodeIfPresent(affinities, forKey: .affinities)
    }
}

// MARK: - StyleGroup Error Handling

enum StyleGroupError: LocalizedError, Equatable {
    case invalidData(field: String, reason: String)
    case missingRequiredField(String)
    case invalidColorFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let field, let reason):
            return "Invalid data for field '\(field)': \(reason)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidColorFormat(let color):
            return "Invalid color format: \(color)"
        }
    }
}

// MARK: - Firestore Mapping Extensions

extension StyleGroup {
    
    /// Cria StyleGroup a partir de dados do Firestore
    /// - Parameter data: Dictionary com dados do documento Firestore
    /// - Returns: StyleGroup opcional (nil se dados inválidos)
    static func fromFirestoreData(_ data: [String: Any]) -> StyleGroup? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let mainGenre = data["mainGenre"] as? String,
              let color = data["color"] as? String,
              let icon = data["icon"] as? String,
              let genres = data["genres"] as? [String] else {
            Logger.shared.error("StyleGroup.fromFirestoreData: Missing required fields", context: "StyleGroup")
            return nil
        }

        guard !id.isEmpty, !name.isEmpty, !mainGenre.isEmpty,
              !color.isEmpty, !icon.isEmpty, !genres.isEmpty else {
            Logger.shared.error("StyleGroup.fromFirestoreData: Empty required fields", context: "StyleGroup")
            return nil
        }

        let styleStrings = data["styleStrings"] as? [String] ?? []

        // Optional fields
        let createdAt: Date? = {
            if let ts = data["createdAt"] as? Timestamp { return ts.dateValue() }
            return nil
        }()
        let description = data["description"] as? String
        let active = data["active"] as? Bool
        let order = data["order"] as? Int
        let imageUrl = data["imageUrl"] as? String

        let translations: [String: StyleGroupTranslation]? = {
            guard let raw = data["translations"] as? [String: [String: Any]] else { return nil }
            var result: [String: StyleGroupTranslation] = [:]
            for (locale, dict) in raw {
                guard let name = dict["name"] as? String else { continue }
                let desc = dict["description"] as? String
                result[locale] = StyleGroupTranslation(name: name, description: desc)
            }
            return result.isEmpty ? nil : result
        }()

        let affinities = data["affinities"] as? [String: Double]

        return StyleGroup(
            id: id,
            name: name,
            mainGenre: mainGenre,
            color: color,
            icon: icon,
            genres: genres,
            styleStrings: styleStrings,
            createdAt: createdAt,
            description: description,
            active: active,
            order: order,
            imageUrl: imageUrl,
            translations: translations,
            affinities: affinities
        )
    }

    func toFirestoreData() -> [String: Any] {
        var result: [String: Any] = [
            "id": id,
            "name": name,
            "mainGenre": mainGenre,
            "color": color,
            "icon": icon,
            "genres": genres,
            "styleStrings": styleStrings
        ]
        if let createdAt { result["createdAt"] = Timestamp(date: createdAt) }
        if let description { result["description"] = description }
        if let active { result["active"] = active }
        if let order { result["order"] = order }
        if let imageUrl { result["imageUrl"] = imageUrl }
        if let translations {
            var raw: [String: [String: Any]] = [:]
            for (locale, t) in translations {
                var dict: [String: Any] = ["name": t.name]
                if let desc = t.description { dict["description"] = desc }
                raw[locale] = dict
            }
            result["translations"] = raw
        }
        if let affinities { result["affinities"] = affinities }
        return result
    }
}

// MARK: - Validation Extensions

extension StyleGroup {
    
    /// Valida formato da cor hexadecimal
    var hasValidColorFormat: Bool {
        let hexPattern = "^#[0-9A-Fa-f]{6}$"
        return color.range(of: hexPattern, options: .regularExpression) != nil
    }
    
    /// Valida se o ícone tem formato esperado
    var hasValidIconFormat: Bool {
        return !icon.isEmpty && 
               !icon.contains(".") && // Não deve ter extensão
               icon.count <= 50 // Limite razoável para nome
    }
    
    /// Validação completa do objeto
    var isFullyValid: Bool {
        return isValid && 
               hasValidColorFormat && 
               hasValidIconFormat &&
               !genres.contains { $0.isEmpty } // Nenhum gênero vazio
    }
}

// MARK: - Debug & Testing

extension StyleGroup {
    
    /// Cria StyleGroup para testes com valores padrão
    static func mock(
        id: String = "test_group",
        name: String = "Test Group",
        mainGenre: String = "Test",
        color: String = "#FF0000",
        icon: String = "test_icon",
        genres: [String] = ["Test Genre"],
        styleStrings: [String] = ["Test Style"],
        active: Bool? = true,
        order: Int? = nil,
        isSelected: Bool = false
    ) -> StyleGroup {
        return StyleGroup(
            id: id,
            name: name,
            mainGenre: mainGenre,
            color: color,
            icon: icon,
            genres: genres,
            styleStrings: styleStrings,
            active: active,
            order: order,
            isSelected: isSelected
        )
    }
}





// MARK: - Color Extension for Hex Support

extension Color {
    
    /// Inicializa Color a partir de string hexadecimal
    /// - Parameter hex: String hex no formato "#RRGGBB"
    /// - Returns: Color opcional (nil se formato inválido)
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        guard hex.count == 6 else { return nil }
        
        let a, r, g, b: UInt64
        (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
