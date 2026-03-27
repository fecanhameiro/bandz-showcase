import Foundation
import FirebaseAnalytics

/// Eventos de analytics definidos para o onboarding
extension AnalyticsManager {
    // Eventos personalizados para onboarding
    struct OnboardingEvents {
        static let onboardingStart = "onboarding_start"
        static let onboardingComplete = "onboarding_complete"
        static let onboardingSkip = "onboarding_skip"
        static let onboardingStep = "onboarding_step"
        static let onboardingServiceSelected = "onboarding_service_selected"
        static let onboardingGenreSelected = "onboarding_genre_selected"
        static let onboardingPermissionSelected = "onboarding_permission_selected"
        static let onboardingArtistSelected = "onboarding_artist_selected"
        static let onboardingPlaceSelected = "onboarding_place_selected"
    }
    
    // Parâmetros personalizados para onboarding
    struct OnboardingParameters {
        static let stepNumber = "step_number"
        static let stepName = "step_name"
        static let timeSpent = "time_spent"
        static let serviceName = "service_name"
        static let genreName = "genre_name"
        static let permissionType = "permission_type"
        static let permissionResponse = "permission_response"
        static let artistId = "artist_id"
        static let artistName = "artist_name"
        static let placeId = "place_id"
        static let placeName = "place_name"
        static let placeCategory = "place_category"
        static let selectedCount = "selected_count"
        static let flowCompletion = "completion_percentage"
    }
}

/// Gerenciador de analytics para o fluxo de onboarding
class OnboardingAnalyticsManager {
    static let shared = OnboardingAnalyticsManager()
    
    private var stepStartTimes = [Int: Date]()
    private var serviceSelections = [String]()
    private var genreSelections = [String]()
    private var artistSelections = [String]()
    private var placeSelections = [String]()
    
    private init() {}
    
    /// Registra o início do fluxo de onboarding
    func logOnboardingStart() {
        AnalyticsManager.shared.logCustomEvent(AnalyticsManager.OnboardingEvents.onboardingStart)
        AnalyticsManager.shared.logScreen(screenName: "Splash", screenClass: "OnboardingSplashView")
    }
    
    /// Registra a conclusão do fluxo de onboarding
    func logOnboardingComplete(selectedServices: [String], selectedGenres: [String], selectedPlaces: [String]) {
        AnalyticsManager.shared.logCustomEvent(
            AnalyticsManager.OnboardingEvents.onboardingComplete,
            parameters: [
                AnalyticsManager.OnboardingParameters.selectedCount: selectedServices.count + selectedGenres.count + selectedPlaces.count,
                AnalyticsManager.OnboardingParameters.flowCompletion: 100
            ]
        )
    }
    
    /// Registra quando o usuário pula o fluxo de onboarding
    func logOnboardingSkipped(atStep step: Int, stepName: String) {
        AnalyticsManager.shared.logCustomEvent(
            AnalyticsManager.OnboardingEvents.onboardingSkip,
            parameters: [
                AnalyticsManager.OnboardingParameters.stepNumber: step,
                AnalyticsManager.OnboardingParameters.stepName: stepName,
                AnalyticsManager.OnboardingParameters.flowCompletion: calculateCompletionPercentage(step: step, totalSteps: 7)
            ]
        )
    }
    
    /// Registra a entrada em uma etapa do onboarding
    func logStepEnter(step: Int, stepName: String) {
        stepStartTimes[step] = Date()
        
        AnalyticsManager.shared.logCustomEvent(
            AnalyticsManager.OnboardingEvents.onboardingStep,
            parameters: [
                AnalyticsManager.OnboardingParameters.stepNumber: step,
                AnalyticsManager.OnboardingParameters.stepName: stepName
            ]
        )
        
        AnalyticsManager.shared.logScreen(screenName: stepName, screenClass: "Onboarding\(step)View")
    }
    
    /// Registra a saída de uma etapa do onboarding
    func logStepExit(step: Int, stepName: String) {
        guard let startTime = stepStartTimes[step] else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        
        AnalyticsManager.shared.logCustomEvent(
            "onboarding_step_completed",
            parameters: [
                AnalyticsManager.OnboardingParameters.stepNumber: step,
                AnalyticsManager.OnboardingParameters.stepName: stepName,
                AnalyticsManager.OnboardingParameters.timeSpent: Int(timeSpent)
            ]
        )
    }
    
    /// Registra a seleção de um serviço de streaming
    func logServiceSelected(serviceName: String, isSelected: Bool) {
        if isSelected {
            if !serviceSelections.contains(serviceName) {
                serviceSelections.append(serviceName)
            }
        } else {
            serviceSelections.removeAll { $0 == serviceName }
        }
        
        AnalyticsManager.shared.logCustomEvent(
            AnalyticsManager.OnboardingEvents.onboardingServiceSelected,
            parameters: [
                AnalyticsManager.OnboardingParameters.serviceName: serviceName,
                AnalyticsManager.ParameterKey.action.rawValue: isSelected ? "selected" : "deselected",
                AnalyticsManager.OnboardingParameters.selectedCount: serviceSelections.count
            ]
        )
    }
    
    /// Registra a seleção de um gênero musical
    func logGenreSelected(genreName: String, isSelected: Bool) {
        if isSelected {
            if !genreSelections.contains(genreName) {
                genreSelections.append(genreName)
            }
        } else {
            genreSelections.removeAll { $0 == genreName }
        }
        
        AnalyticsManager.shared.logCustomEvent(
            AnalyticsManager.OnboardingEvents.onboardingGenreSelected,
            parameters: [
                AnalyticsManager.OnboardingParameters.genreName: genreName,
                AnalyticsManager.ParameterKey.action.rawValue: isSelected ? "selected" : "deselected",
                AnalyticsManager.OnboardingParameters.selectedCount: genreSelections.count
            ]
        )
    }
    
    /// Registra a resposta do usuário a uma permissão
    func logPermissionResponse(permissionType: String, response: String) {
        AnalyticsManager.shared.logCustomEvent(
            AnalyticsManager.OnboardingEvents.onboardingPermissionSelected,
            parameters: [
                AnalyticsManager.OnboardingParameters.permissionType: permissionType,
                AnalyticsManager.OnboardingParameters.permissionResponse: response
            ]
        )
    }
    
    /// Registra a seleção de um artista
    func logArtistSelected(artistId: String, artistName: String, isSelected: Bool) {
        if isSelected {
            if !artistSelections.contains(artistId) {
                artistSelections.append(artistId)
            }
        } else {
            artistSelections.removeAll { $0 == artistId }
        }
        
        AnalyticsManager.shared.logCustomEvent(
            AnalyticsManager.OnboardingEvents.onboardingArtistSelected,
            parameters: [
                AnalyticsManager.OnboardingParameters.artistId: artistId,
                AnalyticsManager.OnboardingParameters.artistName: artistName,
                AnalyticsManager.ParameterKey.action.rawValue: isSelected ? "selected" : "deselected",
                AnalyticsManager.OnboardingParameters.selectedCount: artistSelections.count
            ]
        )
    }
    
    /// Registra a seleção de um lugar
    func logPlaceSelected(placeId: String, placeName: String, placeCategory: String, isSelected: Bool) {
        if isSelected {
            if !placeSelections.contains(placeId) {
                placeSelections.append(placeId)
            }
        } else {
            placeSelections.removeAll { $0 == placeId }
        }
        
        AnalyticsManager.shared.logCustomEvent(
            AnalyticsManager.OnboardingEvents.onboardingPlaceSelected,
            parameters: [
                AnalyticsManager.OnboardingParameters.placeId: placeId,
                AnalyticsManager.OnboardingParameters.placeName: placeName,
                AnalyticsManager.OnboardingParameters.placeCategory: placeCategory,
                AnalyticsManager.ParameterKey.action.rawValue: isSelected ? "selected" : "deselected",
                AnalyticsManager.OnboardingParameters.selectedCount: placeSelections.count
            ]
        )
    }
    
    /// Calcula a porcentagem de conclusão com base na etapa atual
    private func calculateCompletionPercentage(step: Int, totalSteps: Int) -> Int {
        let percentage = (Float(step) / Float(totalSteps)) * 100
        return Int(percentage)
    }
}