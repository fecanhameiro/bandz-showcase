//
//  OnboardingFavoritePlacesHelpers.swift
//  Bandz
//
//  Data management and logging helpers extracted from OnboardingFavoritePlacesView.
//

import SwiftUI

// MARK: - Data Management & Logging Helpers
extension OnboardingFavoritePlacesView {

    // MARK: - Data Loading

    func loadPlaces() {
        isLoading = true
        placesError = nil

        Task {
            do {
                // Carregar places usando o PlaceService (cache-first strategy)
                let loadedPlaces = try await placeService.loadPlaces()

                // Carregar dados do usuário para ordenação usando UserDataManager
                let currentData = userDataManager?.currentUserData
                let userExpandedGenres = currentData?.preferences.expandedGenres ?? []
                let userGenreIds = currentData?.preferences.favoriteGenreIds ?? []
                let userLocation = currentData?.preferences.userLocation

                // Criar seções ordenadas usando PlaceService (dual-strategy: ID + nome)
                let sections = placeService.createPlacesSections(
                    from: loadedPlaces,
                    userExpandedGenres: userExpandedGenres,
                    userGenreIds: userGenreIds,
                    userLocation: userLocation
                )

                await MainActor.run {
                    self.places = loadedPlaces
                    self.placeSections = sections
                    self.isLoading = false
                    self.placesError = nil

                    withAnimation(searchToggleAnimation) {
                        self.updateBottomBarMode(preserveSearch: true)
                    }

                    // Iniciar animação após carregamento
                    startPlacesAnimation()
                }
                if loadedPlaces.isEmpty {
                    logPlacesWarning("Place service returned no places for onboarding")
                }

            } catch {
                await MainActor.run {
                    self.placesError = error
                    self.isLoading = false
                    logPlacesError("Failed to load places", error: error)
                }
            }
        }
    }

    // MARK: - Animation

    func startElementsAnimation() {
        guard !hasElementsAnimated else { return }
        hasElementsAnimated = true

        Task { @MainActor in
            await OnboardingAnimation.cascade(reduceMotion: reduceMotion, steps: [
                { animateStepHeader = true },
                { animateTitle = true }
            ])
        }
    }

    private func startPlacesAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        if reduceMotion {
            animateHeaders = true
            animatePlaces = true
            return
        }

        logger.debug("Starting places animation", context: loggingContext)
        // Animar headers primeiro
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            animateHeaders = true
        }

        // Animar places depois
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            animatePlaces = true
        }

        // Disable places entrance animation quickly so that tiles appearing from scroll
        // show instantly instead of popping in with a stagger delay.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }
            animatePlaces = false
        }
    }

    // MARK: - Place Selection

    func togglePlace(_ place: Place) {
        let currentPlaces = userDataManager?.currentUserData?.preferences.favoritePlaces ?? []
        var updatedPlaces = currentPlaces

        // Update places array
        if let index = updatedPlaces.firstIndex(of: place) {
            updatedPlaces.remove(at: index)
        } else {
            updatedPlaces.append(place)
        }

        // Update through UserDataManager
        userDataManager?.updatePlaces(updatedPlaces)

        withAnimation(searchToggleAnimation) {
            updateBottomBarMode(preserveSearch: true)
        }

        // Analytics
        AnalyticsManager.shared.logCustomEvent("onboarding_place_selected", parameters: [
            "place": place.name,
            "place_type": "\(place.placeType)",
            "total_selected": updatedPlaces.count
        ])

        // Haptic feedback
        HapticManager.shared.impact(style: .light)
    }

    // MARK: - Logging Helpers

    func logPlacesWarning(_ message: String, metadata: [String: Any] = [:]) {
        let combined = placesMetadata(extra: metadata)
        logger.warning(message, metadata: combined, context: loggingContext)
    }

    func logPlacesError(_ message: String, error: Error, metadata: [String: Any] = [:]) {
        var combined = placesMetadata(extra: metadata)
        combined["error.context"] = message
        combined["error.type"] = String(describing: type(of: error))
        logger.log(error: error, metadata: combined, context: loggingContext)
    }

    private func placesMetadata(extra: [String: Any] = [:]) -> [String: Any] {
        var metadata: [String: Any] = [
            "feature": "Onboarding",
            "screen": "OnboardingFavoritePlacesView",
            "tags": ["Onboarding", "Places"],
            "selected_places_count": selectedPlaces.count,
            "sections_count": placeSections.count
        ]

        if !places.isEmpty {
            metadata["places_count"] = places.count
        }

        for (key, value) in extra {
            metadata[key] = value
        }
        return metadata
    }

    // MARK: - Subtitle Generation

    func generateSubtitle(for place: Place) -> String {
        // Se não há gêneros, não mostrar subtitle
        guard !place.styleGroupGenres.isEmpty else {
            return ""
        }

        // Usar extensão para processar gêneros
        let processedGenres = place.processedGenres

        // Pegar os primeiros 2 gêneros processados e formatar com hashtag
        let mainGenres = Array(processedGenres.prefix(2))
        let hashtagGenres = mainGenres.map { "#\($0.lowercased())" }

        // Se há mais de 2 gêneros, adicionar indicador
        if processedGenres.count > 2 {
            let extraCount = processedGenres.count - 2
            return "\(hashtagGenres.joined(separator: " ")) +\(extraCount)"
        } else {
            return hashtagGenres.joined(separator: " ")
        }
    }

    // MARK: - User Location

    func getCurrentUserLocation() -> UserLocation? {
        return userDataManager?.currentUserData?.preferences.userLocation
    }
}
