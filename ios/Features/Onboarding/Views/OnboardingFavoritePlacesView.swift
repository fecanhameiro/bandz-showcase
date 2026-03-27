//
//  FavoritePlacesView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 15/06/25.
//

import SwiftUI
import UIKit

// MARK: - Favorite Places Onboarding View
struct OnboardingFavoritePlacesView: View {
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion
    @SwiftUI.Environment(UserDataManager.self) var userDataManager: UserDataManager?
    @Inject var placeService: PlaceService
    @Inject var imageService: ImageService
    @Inject var logger: Logger
    let loggingContext = "Onboarding.FavoritePlaces"

    // Computed property based on UserDataManager state
    var selectedPlaces: Set<Place> {
        Set(userDataManager?.currentUserData?.preferences.favoritePlaces ?? [])
    }
    @State var hasAnimated = false
    @State var hasElementsAnimated = false
    @State var animateStepHeader = false
    @State var animateTitle = false
    @State var animatePlaces = false
    @State var animateHeaders = false
    @State var searchText = ""
    @State var appliedSearchText = ""
    @State var bottomBarMode: BottomBarMode = .idleNoSelection
    @State var places: [Place] = []
    @State var placeSections: [PlacesSection] = []
    @State var isLoading = false
    @State var placesError: Error? = nil
    @State private var isSaving = false
    @FocusState var searchFieldFocus: SearchFieldFocus?
    @State private var keyboardHeight: CGFloat = 0
    @Namespace var searchTransitionNamespace
    @State private var isKeyboardAnimating = false
    @State var isSearchBarExpanded = false
    @State var searchExpansionTask: Task<Void, Never>?

    var searchToggleAnimation: Animation {
        .interactiveSpring(response: 0.5, dampingFraction: 0.82, blendDuration: 0.25)
    }

    var filterResultsAnimation: Animation {
        .spring(response: 0.55, dampingFraction: 0.88, blendDuration: 0.3)
    }

    let onContinue: () -> Void
    let onBack: () -> Void
    var showsStepHeader: Bool = true

    enum PresentationContext {
        case onboarding
        case profile
    }

    var context: PresentationContext = .onboarding

    enum BottomBarMode: Equatable {
        case idleNoSelection
        case idleWithSelection
        case searchActive
    }

    enum SearchFieldFocus: Hashable {
        case staging
        case visible
    }

    private var currentStep: Int { OnboardingStep.favoritePlaces.stepNumber }
    private let placesScrollAnchorID = "OnboardingFavoritePlacesScrollTop"
    private let searchScrollDelay: Double = 0.18

    // MARK: - Filtering

    private var activeSearchText: String {
        appliedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredSections: [(section: PlacesSection, places: [Place])] {
        filteredSections(for: activeSearchText)
    }

    func filteredSections(for query: String) -> [(section: PlacesSection, places: [Place])] {
        guard !query.isEmpty else {
            return placeSections.map { ($0, $0.places) }
        }

        return placeSections.compactMap { section in
            let filteredPlaces = section.places.filter { $0.name.localizedCaseInsensitiveContains(query) }
            guard !filteredPlaces.isEmpty else { return nil }
            return (section, filteredPlaces)
        }
    }

    private var isSearchPresentationReady: Bool {
        bottomBarMode == .searchActive && isSearchBarExpanded
    }

    // MARK: - Body

    var body: some View {
        GradientBackgroundView(type: .onboarding) {
            VStack(spacing: SpacingSystem.Size.none) {
                // Step Header
                if shouldShowStepHeader {
                    OnboardingStepHeader(
                        currentStep: currentStep,
                        accentColor: ColorSystem.Brand.primary,
                        onStepTapped: { _ in
                            onBack()
                        }
                    )
                    .offset(y: animateStepHeader ? 0 : -15)
                    .opacity(animateStepHeader ? 1.0 : 0.0)
                    .animation(OnboardingAnimation.staggerDelay(index: 0), value: animateStepHeader)
                }

                if isSearchPresentationReady == false {
                    titleSection
                        .padding(.top, titleSectionTopPadding)
                        .padding(.horizontal, SpacingSystem.Size.lg)
                        .offset(y: animateTitle ? 0 : -20)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .animation(OnboardingAnimation.staggerDelay(index: 1), value: animateTitle)
                }

                placesGridSection
                    .padding(.top, SpacingSystem.Size.sm)

                Spacer()
            }
            .overlay(alignment: .bottom) {
                bottomOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startElementsAnimation()
            updateBottomBarMode(preserveSearch: false)
            loadPlaces()
        }
        .onChange(of: searchText) { _, newValue in
            handleSearchTextChange(newValue)
        }
        .onChange(of: selectedPlaces.count) { _, _ in
            withAnimation(searchToggleAnimation) {
                updateBottomBarMode(preserveSearch: true)
            }
        }
        .onDisappear {
            searchExpansionTask?.cancel()
            searchExpansionTask = nil
            keyboardHeight = 0
            isSearchBarExpanded = false
            searchFieldFocus = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            handleKeyboard(notification: notification, isShowing: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
            handleKeyboard(notification: notification, isShowing: false)
        }
        .onChange(of: searchFieldFocus) { _, newFocus in
            handleSearchFocusChange(newFocus)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: SpacingSystem.Size.xs) {
            Text("onboarding.favorite_places_title".localized)
                .h3(alignment: .center)
                .bandzForegroundStyle(.primary)
                .lineLimit(nil)

            Text(favoritePlacesSubtitleText)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .lineLimit(nil)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: selectedPlaces.count)
        }
    }

    private var favoritePlacesSubtitleText: String {
        let count = selectedPlaces.count
        if count == 0 {
            return "onboarding.place_suggestion_based_on_style".localized
        }
        return String(format: "onboarding.favorite_places.selected_count".localized, count)
    }

    private var titleSectionTopPadding: CGFloat {
        if shouldShowStepHeader {
            return SpacingSystem.Size.xs
        }
        return isSearchPresentationReady ? SpacingSystem.Size.sm : SpacingSystem.Size.lg
    }

    private var shouldShowStepHeader: Bool {
        showsStepHeader && context == .onboarding && !isSearchPresentationReady
    }

    private var primaryButtonTitle: String {
        switch context {
        case .onboarding:
            return isSaving ? "common.saving".localized : "onboarding.continue".localized
        case .profile:
            return isSaving ? "profile.update_button_loading".localized : "profile.update_button".localized
        }
    }

    var circleButtonSize: CGFloat {
        SpacingSystem.Size.xxxl * 1.2
    }

    // MARK: - Bottom Overlay

    private var bottomOverlay: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let keyboardOffset = keyboardOffset(for: safeAreaBottom)
            let basePadding = bottomBarBottomPadding(for: safeAreaBottom)

            VStack(spacing: SpacingSystem.Size.none) {
                Spacer()

                switch bottomBarMode {
                case .idleNoSelection:
                    HStack(spacing: SpacingSystem.Size.none) {
                        Spacer()
                        floatingSearchButton
                    }
                    .padding(.horizontal, SpacingSystem.Size.lg)
                    .padding(.bottom, floatingButtonPadding(for: safeAreaBottom) + keyboardOffset)

                case .idleWithSelection, .searchActive:
                    bottomBarGlassContent(
                        safeAreaBottom: safeAreaBottom,
                        keyboardOffset: keyboardOffset,
                        basePadding: basePadding
                    )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private func bottomBarGlassContent(
        safeAreaBottom: CGFloat,
        keyboardOffset: CGFloat,
        basePadding: CGFloat
    ) -> some View {
        let isExpandedSearch = bottomBarMode == .searchActive && isSearchBarExpanded
        let pillRadius = isExpandedSearch ? SpacingSystem.Size.lg : SpacingSystem.Size.xl

        bottomBarContent
            .padding(.horizontal, isExpandedSearch ? SpacingSystem.Size.md : SpacingSystem.Size.xl)
            .padding(.vertical, SpacingSystem.Size.sm)
            .glassPillBackground(cornerRadius: pillRadius)
            .padding(.horizontal, isExpandedSearch ? SpacingSystem.Size.sm : SpacingSystem.Size.md)
            .padding(.bottom, (isExpandedSearch ? SpacingSystem.Size.xs : SpacingSystem.Size.sm) + keyboardOffset)
            .animation(isKeyboardAnimating ? nil : searchToggleAnimation, value: isSearchBarExpanded)
            .animation(isKeyboardAnimating ? nil : searchToggleAnimation, value: bottomBarMode)
    }

    private func bottomBarBottomPadding(for safeArea: CGFloat) -> CGFloat {
        max(0, safeArea - SpacingSystem.Size.sm)
    }

    private func floatingButtonPadding(for safeArea: CGFloat) -> CGFloat {
        let minimumPadding = SpacingSystem.Size.xl
        let safeAreaPadding = safeArea + SpacingSystem.Size.sm
        return max(minimumPadding, safeAreaPadding)
    }

    private func keyboardOffset(for safeArea: CGFloat) -> CGFloat {
        max(0, keyboardHeight - safeArea)
    }

    @ViewBuilder
    private var bottomBarContent: some View {
        switch bottomBarMode {
        case .idleNoSelection:
            EmptyView()
        case .idleWithSelection:
            HStack(spacing: SpacingSystem.Size.md) {
                continueButton
                searchTriggerButton
            }
        case .searchActive:
            searchBarContent
        }
    }

    private var continueButton: some View {
        BandzGlassButton(
            primaryButtonTitle,
            isLoading: isSaving,
            style: .darkGlass
        ) {
            handleContinue()
        }
        .disabled(isSaving)
    }

    private var searchTriggerButton: some View {
        searchActivationButton(
            shadowOpacity: 0.12,
            shadowRadius: 4,
            shadowOffsetY: 3
        )
    }

    private var floatingSearchButton: some View {
        searchActivationButton()
    }

    // MARK: - Bottom Bar State

    func updateBottomBarMode(preserveSearch: Bool) {
        if preserveSearch && bottomBarMode == .searchActive {
            return
        }

        let hasSelection = !selectedPlaces.isEmpty
        bottomBarMode = hasSelection ? .idleWithSelection : .idleNoSelection
        if bottomBarMode != .searchActive {
            isSearchBarExpanded = false
            searchExpansionTask?.cancel()
            searchExpansionTask = nil
            searchFieldFocus = nil
        }
    }

    // MARK: - Keyboard Handling

    private func handleKeyboard(notification: Notification, isShowing: Bool) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        let height = isShowing ? frame.height : 0

        let animation = makeKeyboardAnimation(duration: duration, curveRaw: curveRaw)
        isKeyboardAnimating = true

        if let animation {
            withAnimation(animation) {
                keyboardHeight = height
            }
        } else {
            keyboardHeight = height
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            isKeyboardAnimating = false
        }
    }

    private func makeKeyboardAnimation(duration: Double, curveRaw: UInt?) -> Animation? {
        guard duration > 0 else { return nil }
        guard let curveRaw,
              let curve = UIView.AnimationCurve(rawValue: Int(curveRaw)) else {
            return .easeOut(duration: duration)
        }

        switch curve {
        case .easeInOut:
            return .easeInOut(duration: duration)
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .linear:
            return .linear(duration: duration)
        @unknown default:
            return .easeOut(duration: duration)
        }
    }

    // MARK: - Search Analytics

    func logSearchAnalytics(for query: String) {
        let sections = filteredSections(for: query)
        let totalResults = sections.reduce(0) { $0 + $1.places.count }
        AnalyticsManager.shared.logCustomEvent("onboarding_place_search", parameters: [
            "search_term": query,
            "results_count": totalResults
        ])
    }

    // MARK: - Places Grid Section

    private var placesGridSection: some View {
        let query = activeSearchText

        return ZStack {
            allPlacesList
                .opacity(query.isEmpty ? 1 : 0)
                .allowsHitTesting(query.isEmpty)
                .accessibilityHidden(!query.isEmpty)

            if !query.isEmpty {
                filteredPlacesList(for: query)
                    .transition(.opacity)
                    .accessibilityHidden(false)
            }
        }
        .animation(filterResultsAnimation, value: appliedSearchText)
    }

    private var allPlacesList: some View {
        ScrollView {
            if isLoading {
                skeletonLoadingSection
            } else if let error = placesError {
                placesErrorStateView(error: error)
            } else if placeSections.isEmpty {
                placesEmptyStateView
            } else {
                LazyVStack(spacing: SpacingSystem.Size.lg, pinnedViews: [.sectionHeaders]) {
                    ForEach(Array(placeSections.enumerated()), id: \.element.id) { enumeratedSection in
                        let sectionIndex = enumeratedSection.offset
                        let section = enumeratedSection.element

                        Section {
                            sectionContent(
                                for: section,
                                places: section.places,
                                sectionIndex: sectionIndex,
                                isFiltering: false
                            )
                        } header: {
                            sectionHeader(
                                for: section,
                                userExpandedGenres: userDataManager?.currentUserData?.preferences.expandedGenres ?? [],
                                visiblePlacesCount: section.places.count,
                                animationDelay: Double(sectionIndex) * 0.1
                            )
                            .padding(.horizontal, SpacingSystem.Size.lg)
                        }
                    }
                }
                .padding(.top, SpacingSystem.Size.md)
                .padding(.bottom, GlassPillLayout.scrollContentInset)
            }
        }
    }

    private func filteredPlacesList(for query: String) -> some View {
        let sections = filteredSections(for: query)
        return ScrollViewReader { proxy in
            ScrollView {
                if sections.isEmpty {
                    emptyFilteredState(for: query)
                        .padding(.top, SpacingSystem.Size.xxxl)
                        .padding(.horizontal, SpacingSystem.Size.lg)
                } else {
                    LazyVStack(spacing: SpacingSystem.Size.lg, pinnedViews: [.sectionHeaders]) {
                        Color.clear
                            .frame(height: 0)
                            .id(placesScrollAnchorID)

                        ForEach(Array(sections.enumerated()), id: \.element.section.id) { enumeratedSection in
                            let sectionIndex = enumeratedSection.offset
                            let section = enumeratedSection.element.section
                            let places = enumeratedSection.element.places

                            Section {
                                sectionContent(
                                    for: section,
                                    places: places,
                                    sectionIndex: sectionIndex,
                                    isFiltering: true
                                )
                            } header: {
                                sectionHeader(
                                    for: section,
                                    userExpandedGenres: userDataManager?.currentUserData?.preferences.expandedGenres ?? [],
                                    visiblePlacesCount: places.count,
                                    animationDelay: Double(sectionIndex) * 0.1
                                )
                                .padding(.horizontal, SpacingSystem.Size.lg)
                            }
                        }
                    }
                    .padding(.top, SpacingSystem.Size.md)
                    .padding(.bottom, GlassPillLayout.scrollContentInset)
                }
            }
            .onChange(of: appliedSearchText) { _, newValue in
                guard isSearchBarExpanded else { return }
                let scrollAction = {
                    proxy.scrollTo(placesScrollAnchorID, anchor: .top)
                }

                if newValue.isEmpty {
                    scrollAction()
                } else {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(searchScrollDelay))
                        guard !Task.isCancelled else { return }
                        guard isSearchBarExpanded else { return }
                        withAnimation(filterResultsAnimation) {
                            scrollAction()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func emptyFilteredState(for query: String) -> some View {
        VStack(spacing: SpacingSystem.Size.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: LayoutSystem.ElementSize.largeIcon, weight: .light))
                .foregroundStyle(ColorSystem.Text.secondary)

            VStack(spacing: SpacingSystem.Size.sm) {
                Text(String(format: "onboarding.favorite_places.no_results".localized, query))
                    .bodyEmphasized(alignment: .center)
                    .bandzForegroundStyle(.primary)

                Text("onboarding.favorite_places.no_results_hint".localized)
                    .bodyRegular(alignment: .center)
                    .bandzForegroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Skeleton Loading Section

    private var skeletonLoadingSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: SpacingSystem.Size.md),
            GridItem(.flexible(), spacing: SpacingSystem.Size.md)
        ], spacing: SpacingSystem.Size.md) {
            ForEach(0..<8, id: \.self) { index in
                OnboardingSkeletonTileView(variant: .rectangle, animationDelay: Double(index) * 0.1)
            }
        }
        .padding(.top, SpacingSystem.Size.md)
        .padding(.horizontal, SpacingSystem.Size.lg)
        .padding(.bottom, SpacingSystem.Size.lg)
    }

    // MARK: - Error State

    private func placesErrorStateView(error: Error) -> some View {
        OnboardingStateView(
            icon: "wifi.exclamationmark",
            titleKey: "onboarding.favorite_places.error_title",
            messageKey: "onboarding.favorite_places.error_message",
            actionKey: "common.try_again",
            isLoading: isLoading
        ) {
            loadPlaces()
        }
    }

    // MARK: - Empty State

    private var placesEmptyStateView: some View {
        OnboardingStateView(
            icon: "building.2",
            titleKey: "onboarding.favorite_places.empty_title",
            messageKey: "onboarding.favorite_places.empty_message",
            actionKey: "onboarding.favorite_places.empty_retry",
            isLoading: isLoading
        ) {
            loadPlaces()
        }
    }

    // MARK: - Helper Functions
    // Data management helpers: OnboardingFavoritePlacesHelpers.swift
    // Search UI & state management: FavoritePlacesSearchBar.swift
    // Section rendering: FavoritePlacesSectionViews.swift

    private func handleContinue() {
        HapticManager.shared.play(.impact(.medium))
        Task {
            if context == .profile {
                await MainActor.run { isSaving = true }
            }

            guard let currentData = userDataManager?.currentUserData else {
                await MainActor.run {
                    if context == .profile { isSaving = false }
                }
                logPlacesWarning("Favorite places continue tapped without user data loaded")
                return
            }

            let selectedPlaces = Set(currentData.preferences.favoritePlaces)

            AnalyticsManager.shared.logCustomEvent("onboarding_places_continue_tapped", parameters: [
                "selected_places": selectedPlaces.map { $0.name },
                "places_count": selectedPlaces.count,
                "preferred_places": selectedPlaces.filter { place in
                    currentData.preferences.expandedGenres.contains { genre in
                        place.styleGroupGenres.map { $0.lowercased() }.contains(genre.lowercased())
                    }
                }.count
            ])

            var shouldDismiss = true
            if context == .profile {
                do {
                    try await userDataManager?.persistFavoritePlaces()
                } catch {
                    logPlacesError("Failed to persist places update", error: error)
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
    OnboardingFavoritePlacesView(
        onContinue: {},
        onBack: {}
    )
}
