//
//  StyleSelectionView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 15/06/25.
//

import SwiftUI


// MARK: - Style Selection Onboarding View
struct OnboardingGenreSelectionView: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContinueButton = false
    
    // MARK: - UserDataManager Integration
    
    @SwiftUI.Environment(UserDataManager.self) private var userDataManager: UserDataManager?
    
    // Computed property based on UserDataManager state
    private var selectedGenres: Set<MusicGenre> {
        Set(userDataManager?.currentUserData?.preferences.favoriteGenres ?? [])
    }
    
    // MARK: - UI State
    @State private var animateStyles = false
    @State private var isSaving = false
    @State private var hasInitialAnimationCompleted = false

    // Animation states — cascade entrance like other onboarding screens
    @State private var hasAnimated = false
    @State private var animateHeader = false
    @State private var animateTitle = false
    
    // MARK: - StyleGroups State Management
    @State private var styleGroups: [StyleGroup] = []
    @State private var isLoadingStyleGroups = false
    @State private var styleGroupsError: Error? = nil
    @State private var hasLoadedOnce = false
    
    @Inject private var genreService: GenreService
    
    let onContinue: () -> Void
    let onBack: () -> Void
    var showsStepHeader: Bool = true
    
    enum PresentationContext {
        case onboarding
        case profile
    }

    var context: PresentationContext = .onboarding
    
    private var currentStep: Int { OnboardingStep.favoriteGenres.stepNumber }

    /// Skeleton placeholder count: use last known style groups count, fallback to 8
    private var skeletonCount: Int {
        let cached = genreService.cachedStyleGroupsCount
        return cached > 0 ? cached : 8
    }

    var body: some View {
        GradientBackgroundView(type: .onboarding) {
            VStack(spacing: SpacingSystem.Size.none) {
                // Step Header — slides down from above
                if shouldShowStepHeader {
                    OnboardingStepHeader(
                        currentStep: currentStep,
                        accentColor: ColorSystem.Brand.primary,
                        onStepTapped: { _ in
                            onBack() // Sempre volta 1 step
                        }
                    )
                    .offset(y: animateHeader ? 0 : -15)
                    .opacity(animateHeader ? 1.0 : 0.0)
                    .animation(OnboardingAnimation.staggerDelay(index: 0), value: animateHeader)
                }

                // Title Section — slides down
                titleSection
                    .padding(.top, shouldShowStepHeader ? SpacingSystem.Size.xs : SpacingSystem.Size.lg)
                    .padding(.horizontal, SpacingSystem.Size.lg)
                    .offset(y: animateTitle ? 0 : -20)
                    .opacity(animateTitle ? 1.0 : 0.0)
                    .animation(OnboardingAnimation.staggerDelay(index: 1), value: animateTitle)
                
                // Content Section - Loading/Error/Success states
                contentSection
                    .padding(.top, SpacingSystem.Size.xs)
                
                Spacer()
            }
            .overlay(alignment: .bottom) {
                // Continue Button with elegant backdrop
                if showContinueButton {
                    BandzGlassButton(
                        primaryButtonTitle,
                        isLoading: isSaving,
                        style: .darkGlass
                    ) {
                        handleContinue()
                    }
                    .onboardingBottomPill()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.4), value: showContinueButton)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startElementsAnimation()
            loadStyleGroups()

            // Update continue button state based on UserDataManager
            showContinueButton = !(userDataManager?.currentUserData?.preferences.favoriteGenres.isEmpty ?? true)
        }
    }

    private var shouldShowStepHeader: Bool {
        showsStepHeader && context == .onboarding
    }

    private var primaryButtonTitle: String {
        switch context {
        case .onboarding:
            return isSaving ? "common.saving".localized : "onboarding.continue".localized
        case .profile:
            return isSaving ? "profile.update_button_loading".localized : "profile.update_button".localized
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: SpacingSystem.Size.xs) {
            Text("onboarding.style_selection_title".localized)
                .h3(alignment: .center)
                .bandzForegroundStyle(.primary)
                .lineLimit(nil)

            Text(genreSubtitleText)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .lineLimit(nil)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: selectedGenres.count)
        }
    }

    private var genreSubtitleText: String {
        let count = selectedGenres.count
        if count == 0 {
            return "onboarding.style_selection_subtitle".localized
        }
        return String(format: "onboarding.genre_selection.selected_count".localized, count)
    }
    
    // MARK: - Content Section with States
    @ViewBuilder
    private var contentSection: some View {
        if isLoadingStyleGroups || (!hasLoadedOnce && styleGroups.isEmpty && styleGroupsError == nil) {
            loadingStateView
        } else if let error = styleGroupsError {
            errorStateView(error: error)
        } else if styleGroups.isEmpty {
            emptyStateView
        } else {
            stylesGridSection
        }
    }
    
    // MARK: - Loading State
    private var loadingStateView: some View {
        ScrollView {
            VStack(spacing: SpacingSystem.Size.lg) {
                // Skeleton loading cards — count based on last known data or default
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: SpacingSystem.Size.md),
                    GridItem(.flexible(), spacing: SpacingSystem.Size.md)
                ], spacing: SpacingSystem.Size.md) {
                    ForEach(0..<skeletonCount, id: \.self) { index in
                        OnboardingSkeletonTileView(
                            variant: .circle,
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }
                .padding(.horizontal, SpacingSystem.Size.lg)
                
            }
            .padding(.top, SpacingSystem.Size.md)
            .padding(.bottom, SpacingSystem.Size.lg)
        }
    }

    // MARK: - Error State
    private func errorStateView(error: Error) -> some View {
        ScrollView {
            OnboardingStateView(
                icon: "wifi.exclamationmark",
                titleKey: "onboarding.genre_selection.error_title",
                messageKey: "onboarding.genre_selection.error_message",
                actionKey: "common.try_again",
                isLoading: isLoadingStyleGroups
            ) {
                loadStyleGroups()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        ScrollView {
            OnboardingStateView(
                icon: "guitars",
                titleKey: "onboarding.genre_selection.empty_title",
                messageKey: "onboarding.genre_selection.empty_message",
                actionKey: "onboarding.genre_selection.empty_retry",
                isLoading: isLoadingStyleGroups
            ) {
                loadStyleGroups()
            }
        }
    }

    // MARK: - Styles Grid Section
    private var stylesGridSection: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: SpacingSystem.Size.md),
                GridItem(.flexible(), spacing: SpacingSystem.Size.md)
            ], spacing: SpacingSystem.Size.md) {
                ForEach(Array(styleGroups.enumerated()), id: \.element.id) { index, styleGroup in
                    let genre = MusicGenre(
                        id: styleGroup.id,
                        name: styleGroup.mainGenre,
                        icon: styleGroup.icon,
                        color: styleGroup.color
                    )

                    UnifiedTileView(
                        title: styleGroup.mainGenre,
                        subtitle: styleGroup.subtitleText,
                        imageName: styleGroup.icon,
                        tileType: .genre(styleGroup.uiColor),
                        actionMode: .selection,
                        isSelected: selectedGenres.contains(genre),
                        isAnimating: animateStyles && !hasInitialAnimationCompleted,
                        animationDelay: Double(index) * 0.1,
                        showDistance: false,
                        distanceText: nil
                    ) {
                        toggleGenre(genre)
                    }
                }
            }
            .padding(.top, SpacingSystem.Size.md)
            .padding(.horizontal, SpacingSystem.Size.lg)
            .padding(.bottom, showContinueButton ? GlassPillLayout.scrollContentInset : SpacingSystem.Size.lg)
        }
    }
    
    
    // MARK: - StyleGroups Loading
    
    /// Carrega StyleGroups com cache-first strategy (UX otimizada)
    /// Shows skeleton only when cache is empty; otherwise data appears instantly.
    private func loadStyleGroups() {
        guard !isLoadingStyleGroups else { return }

        // Show skeleton only if no cached data available (avoids empty content flash)
        let hasCachedData = genreService.cachedStyleGroupsCount > 0
        if !hasCachedData {
            isLoadingStyleGroups = true
        }
        styleGroupsError = nil

        Task {
            do {
                let groups = try await genreService.loadStyleGroups()

                await MainActor.run {
                    self.styleGroups = groups
                    isLoadingStyleGroups = false
                    styleGroupsError = nil
                    hasLoadedOnce = true

                    animateStyles = false
                    startStylesAnimation()
                }
            } catch {
                await MainActor.run {
                    styleGroupsError = error
                    isLoadingStyleGroups = false
                }
            }
        }
    }
    
    // MARK: - Animation Functions
    private func startElementsAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        Task { @MainActor in
            await OnboardingAnimation.cascade(reduceMotion: reduceMotion, steps: [
                { animateHeader = true },
                { animateTitle = true }
            ])
        }
    }

    // MARK: - Helper Functions
    private func startStylesAnimation() {
        // Garantir que a animação só inicia após dados carregados
        guard !styleGroups.isEmpty && !hasInitialAnimationCompleted else { return }

        if reduceMotion {
            animateStyles = true
            hasInitialAnimationCompleted = true
            return
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            animateStyles = true
        }

        // Disable entrance animation quickly so that tiles appearing from scroll
        // show instantly instead of popping in with a stagger delay.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            hasInitialAnimationCompleted = true
        }
    }
    
    /// Toggle genre selection using UserDataManager as single source of truth
    private func toggleGenre(_ genre: MusicGenre) {
        let currentGenres = userDataManager?.currentUserData?.preferences.favoriteGenres ?? []
        var updatedGenres = currentGenres
        
        // Update genres array
        if let index = updatedGenres.firstIndex(of: genre) {
            updatedGenres.remove(at: index)
        } else {
            updatedGenres.append(genre)
        }
        
        // Update through UserDataManager
        userDataManager?.updateGenres(updatedGenres)

        // Haptic feedback a cada toggle de gênero
        HapticManager.shared.selection()

        // Milestone haptic bonus ao atingir 3 gêneros
        if updatedGenres.count == 3 {
            HapticManager.shared.play(.notification(.success))
        }

        // Animate UI updates
        withAnimation(.easeInOut(duration: 0.4).delay(0.1)) {
            showContinueButton = !updatedGenres.isEmpty
        }
    }
    private func handleContinue() {
        HapticManager.shared.play(.impact(.medium))
        Task {
            if context == .profile {
                await MainActor.run { isSaving = true }
            }

            // expandedGenres and favoriteGenreIds are already set by updateGenres() on each toggle

            var shouldDismiss = true
            if context == .profile {
                do {
                    try await userDataManager?.persistFavoriteGenres()
                } catch {
                    shouldDismiss = false
                }
            }

            await MainActor.run {
                if context == .profile {
                    isSaving = false
                }
                if shouldDismiss {
                    onContinue()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingGenreSelectionView(
        onContinue: {},
        onBack: {}
    )
}
