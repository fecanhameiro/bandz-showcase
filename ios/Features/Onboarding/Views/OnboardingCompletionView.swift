//
//  OnboardingCompletionView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 15/06/25.
//

import SwiftUI

struct OnboardingCompletionView: View {
    @SwiftUI.Environment(UserDataManager.self) private var userDataManager: UserDataManager?
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    // MARK: - Properties
    let coordinator: BandzOnboardingCoordinator
    let onComplete: () -> Void

    // MARK: - Animation States
    @State private var hasAnimated = false
    @State private var showInnerRing = false
    @State private var showOuterRing = false
    @State private var animateContent = false
    @State private var animateButton = false
    @State private var triggerShockwave = false
    @State private var highlightedGenre: MusicGenre?

    // MARK: - CTA Cycling (genres + places + "Bandz")
    @State private var currentCycleIndex: Int = 0
    @State private var cycleTask: Task<Void, Never>?

    // MARK: - Body
    var body: some View {
        GradientBackgroundView(type: .onboarding, isAnimated: colorScheme == .light) {
            ZStack {
                // Layer 1: Cosmic starfield — living cosmos behind everything
                CosmicStarfieldCanvas(
                    genreColors: genreColors,
                    isVisible: showInnerRing
                )
                .ignoresSafeArea()

                // Layer 2: Genre aurora — atmospheric glow that reacts to orbit
                GenreAuroraBackground(
                    highlightedGenre: highlightedGenre,
                    isActive: showInnerRing
                )
                .ignoresSafeArea()

                // Layer 3: Main content
                VStack(spacing: SpacingSystem.Size.none) {
                    Spacer()

                    // Title and Content Section
                    contentSection
                        .padding(.horizontal, SpacingSystem.Size.lg)
                        .offset(y: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)

                    Spacer()
                        .frame(height: SpacingSystem.Size.lg)

                    // Hero Orbit with shockwave overlay
                    orbitSection
                        .overlay {
                            CosmicShockwaveOverlay(
                                isTriggered: triggerShockwave,
                                accentColor: highlightedGenre.flatMap { Color(hex: $0.color) } ?? ColorSystem.Brand.primary
                            )
                        }

                    // Caption
                    Text("onboarding.completion.orbit_caption".localized)
                        .bodyRegular(alignment: .center)
                        .bandzForegroundStyle(.secondary)
                        .opacity(showInnerRing ? 0.8 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.3), value: showInnerRing)
                        .padding(.top, SpacingSystem.Size.sm)

                    Spacer()
                }
                .overlay(alignment: .bottom) {
                    if animateButton {
                        Button(action: { handleStartExploring() }) {
                            scrambleButtonLabel
                        }
                        .buttonStyle(UnifiedGlassButtonStyle(opacity: .ultraStrong, variant: .dark))
                        .onboardingBottomPill()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.4), value: animateButton)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()
        .onAppear {
            AnalyticsManager.shared.logCustomEvent("onboarding_completion_viewed")
            startCelebrationAnimation()

            // Trigger single atomic Firebase persistence
            Task { await coordinator.persistOnboardingData() }
        }
        .onDisappear {
            cycleTask?.cancel()
        }
    }

    // MARK: - Animation
    private func startCelebrationAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        if reduceMotion {
            showInnerRing = true
            showOuterRing = true
            animateContent = true
            animateButton = true
            startCycling()
            return
        }

        Task { @MainActor in
            // 1. Big Bang — shockwave + inner ring + starfield fade in
            HapticManager.shared.play(.notification(.success))
            HapticManager.shared.impact(style: .heavy)
            showInnerRing = true
            triggerShockwave = true

            // 2. Outer ring expands from center
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            HapticManager.shared.impact(style: .light)
            showOuterRing = true

            // 3. Title + subtitle slide in (aurora + constellation already animating)
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                animateContent = true
            }

            // 4. CTA button bounces up
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            HapticManager.shared.impact(style: .light)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animateButton = true
            }

            // 5. Start CTA cycling after button is visible
            startCycling()
        }
    }

    // MARK: - CTA Cycling

    private var favoriteGenres: [MusicGenre] {
        userDataManager?.currentUserData?.preferences.favoriteGenres ?? []
    }

    private var favoritePlaces: [Place] {
        userDataManager?.currentUserData?.preferences.favoritePlaces ?? []
    }

    /// Combined cycle: genre names → place names → "Bandz"
    private var cycleItems: [String] {
        var items: [String] = []
        items.append(contentsOf: favoriteGenres.map(\.name))
        items.append(contentsOf: favoritePlaces.map(\.name))
        items.append("Bandz")
        return items
    }

    private var currentCycleName: String {
        let items = cycleItems
        guard !items.isEmpty else { return "Bandz" }
        return items[currentCycleIndex % items.count]
    }

    private func startCycling() {
        let items = cycleItems
        guard items.count > 1 else { return }

        cycleTask?.cancel()
        cycleTask = Task { @MainActor in
            // Wait before first cycle so user reads the initial item
            try? await Task.sleep(for: .seconds(3))

            while !Task.isCancelled {
                currentCycleIndex = (currentCycleIndex + 1) % items.count
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    // MARK: - Transition Handling
    private func handleStartExploring() {
        switch coordinator.persistenceState {
        case .saved:
            HapticManager.shared.impact(style: .light)
            AnalyticsManager.shared.logCustomEvent("onboarding_completion_start_exploring_tapped")
            onComplete()
        case .failed:
            HapticManager.shared.play(.notification(.warning))
            Task { await coordinator.persistOnboardingData() }
        case .saving, .pending:
            break
        }
    }

    // MARK: - Orbit Section

    private var orbitSize: CGFloat {
        let screenWidth = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width) ?? 390
        return min(screenWidth * 0.75, 300)
    }

    private var orbitSection: some View {
        BandzOrbitView(
            genres: userDataManager?.currentUserData?.preferences.favoriteGenres ?? [],
            places: userDataManager?.currentUserData?.preferences.favoritePlaces ?? [],
            showInnerRing: showInnerRing,
            showOuterRing: showOuterRing,
            userLocation: userDataManager?.currentUserData?.preferences.userLocation,
            onGenreHighlightChanged: { genre in
                highlightedGenre = genre
            }
        )
        .frame(width: orbitSize, height: orbitSize)
    }

    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: SpacingSystem.Size.md) {
            Text("onboarding.completion.title".localized)
                .h1(alignment: .center)
                .bandzForegroundStyle(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .modifier(TextShimmerModifier())

            Text(personalizedSubtitle)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Personalized Content
    private var personalizedSubtitle: String {
        if let userLocation = userDataManager?.currentUserData?.preferences.userLocation,
           let city = userLocation.city, !city.isEmpty {
            return String(format: "onboarding.completion.subtitle_with_city".localized, city)
        }

        return "onboarding.completion.subtitle".localized
    }

    private var genreColors: [Color] {
        (userDataManager?.currentUserData?.preferences.favoriteGenres ?? [])
            .compactMap { Color(hex: $0.color) }
    }

    // MARK: - Scramble Button Label

    @ViewBuilder
    private var scrambleButtonLabel: some View {
        switch coordinator.persistenceState {
        case .pending, .saving:
            HStack(spacing: SpacingSystem.Size.sm) {
                ProgressView()
                    .tint(ColorSystem.Text.inverse)
                Text("onboarding.completion.saving".localized)
            }
        case .failed:
            Text("onboarding.completion.retry".localized)
        case .saved:
            HStack(spacing: SpacingSystem.Size.none) {
                Text("onboarding.completion.explore_prefix".localized)
                TextScrambleView(text: currentCycleName)
            }
            .lineLimit(1)
            .truncationMode(.tail)
        }
    }
}

// MARK: - Preview
// Preview requires DI-created coordinator — use OnboardingContainerView preview instead
