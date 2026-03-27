//
//  FavoritePlacesSearchBar.swift
//  Bandz
//
//  Search bar UI components and search state management for FavoritePlacesView.
//  Extracted from OnboardingFavoritePlacesView for maintainability.
//

import SwiftUI

// MARK: - Search UI Components

extension OnboardingFavoritePlacesView {

    // MARK: - Adaptive Search Colors

    private var searchIconColor: Color {
        colorScheme == .dark ? ColorSystem.Text.primary : ColorSystem.Brand.primary
    }

    private var searchTextColor: Color {
        ColorSystem.Text.primary
    }

    private var searchClearColor: Color {
        colorScheme == .dark ? ColorSystem.Text.secondary : ColorSystem.Brand.primary.opacity(0.5)
    }

    private var searchFieldFillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : ColorSystem.Brand.primary.opacity(0.08)
    }

    private var searchFieldStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.22) : ColorSystem.Brand.primary.opacity(0.14)
    }

    // MARK: - Search Input Field

    private var searchInputField: some View {
        HStack(spacing: SpacingSystem.Size.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Typography.FontSize.body, weight: .semibold))
                .foregroundStyle(searchIconColor)
                .matchedGeometryEffect(id: "searchIcon", in: searchTransitionNamespace)

            TextField(
                "onboarding.search_favorite_place_placeholder".localized,
                text: $searchText
            )
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            .keyboardType(.default)
            .focused($searchFieldFocus, equals: .visible)
            .foregroundStyle(searchTextColor)
            .submitLabel(.search)
            .onSubmit {
                commitSearch()
            }

            if !searchText.isEmpty {
                Button {
                    HapticManager.shared.impact(style: .light)
                    let wasFiltering = !appliedSearchText.isEmpty
                    searchText = ""
                    if wasFiltering {
                        withAnimation(filterResultsAnimation) {
                            appliedSearchText = ""
                        }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Typography.FontSize.body, weight: .medium))
                        .foregroundStyle(searchClearColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearSearchAccessibilityLabel)
            }
        }
        .padding(.horizontal, SpacingSystem.Size.md)
        .frame(maxWidth: .infinity)
        .frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: SpacingSystem.Size.md, style: .continuous)
                .fill(searchFieldFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: SpacingSystem.Size.md, style: .continuous)
                        .stroke(searchFieldStrokeColor, lineWidth: 1)
                )
                .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNamespace)
        )
    }

    // MARK: - Search Bar Content

    var searchBarContent: some View {
        ZStack(alignment: .trailing) {
            hiddenFocusTextField
            if isSearchBarExpanded {
                expandedSearchBar
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                collapsedSearchPlaceholder
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Expanded Search Bar

    private var expandedSearchBar: some View {
        HStack(spacing: SpacingSystem.Size.sm) {
            searchInputField

            Button {
                HapticManager.shared.impact(style: .soft)
                dismissSearch()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: Typography.FontSize.medium, weight: .semibold))
                    .foregroundStyle(searchIconColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(searchCloseAccessibilityLabel)
        }
    }

    // MARK: - Collapsed Placeholder

    private var collapsedSearchPlaceholder: some View {
        searchActivationVisual(shadowOpacity: 0.12, shadowRadius: 4, shadowOffsetY: 3)
            .transition(.opacity)
    }

    // MARK: - Hidden Focus Field (for staged keyboard appearance)

    private var hiddenFocusTextField: some View {
        TextField("", text: $searchText)
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            .keyboardType(.default)
            .focused($searchFieldFocus, equals: .staging)
            .submitLabel(.search)
            .opacity(0.01)
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Search Activation Visual

    private var searchButtonFillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : ColorSystem.Brand.primary.opacity(0.10)
    }

    private var searchButtonStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.35) : ColorSystem.Brand.primary.opacity(0.16)
    }

    private var searchButtonIconColor: Color {
        colorScheme == .dark ? ColorSystem.Text.primary : ColorSystem.Brand.primary
    }

    func searchActivationVisual(
        shadowOpacity: Double = 0.18,
        shadowRadius: CGFloat = 6,
        shadowOffsetY: CGFloat = 6
    ) -> some View {
        RoundedRectangle(cornerRadius: circleButtonSize / 2, style: .continuous)
            .fill(searchButtonFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: circleButtonSize / 2, style: .continuous)
                    .stroke(searchButtonStrokeColor, lineWidth: 1)
            )
            .matchedGeometryEffect(id: "searchBackground", in: searchTransitionNamespace)
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowOffsetY)
            .overlay {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: Typography.FontSize.medium, weight: .semibold))
                    .foregroundStyle(searchButtonIconColor)
                    .matchedGeometryEffect(id: "searchIcon", in: searchTransitionNamespace)
            }
            .frame(width: circleButtonSize, height: circleButtonSize)
    }

    // MARK: - Search Activation Button

    func searchActivationButton(
        shadowOpacity: Double = 0.18,
        shadowRadius: CGFloat = 6,
        shadowOffsetY: CGFloat = 6
    ) -> some View {
        Button {
            HapticManager.shared.impact(style: .soft)
            activateSearch()
        } label: {
            searchActivationVisual(
                shadowOpacity: shadowOpacity,
                shadowRadius: shadowRadius,
                shadowOffsetY: shadowOffsetY
            )
        }
        .buttonStyle(GlassCircleButtonStyle())
        .accessibilityLabel(searchOpenAccessibilityLabel)
    }

    // MARK: - Search State Management

    func handleSearchFocusChange(_ focus: SearchFieldFocus?) {
        guard bottomBarMode == .searchActive else { return }
        guard searchExpansionTask == nil else { return }
        guard focus == nil else { return }
        guard searchText.isEmpty else { return }
        dismissSearch()
    }

    func handleSearchTextChange(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespaces)

        guard bottomBarMode == .searchActive else {
            if !appliedSearchText.isEmpty {
                withAnimation(filterResultsAnimation) {
                    appliedSearchText = ""
                }
            }
            return
        }

        if trimmed.isEmpty && !appliedSearchText.isEmpty {
            withAnimation(filterResultsAnimation) {
                appliedSearchText = ""
            }
        }
    }

    private func commitSearch() {
        guard bottomBarMode == .searchActive else { return }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if searchText != trimmed {
            searchText = trimmed
        }

        if appliedSearchText != trimmed {
            if trimmed.isEmpty {
                appliedSearchText = ""
            } else {
                withAnimation(filterResultsAnimation) {
                    appliedSearchText = trimmed
                }
            }
        }

        if !trimmed.isEmpty {
            logSearchAnalytics(for: trimmed)
        }

        searchFieldFocus = nil
        HapticManager.shared.impact(style: .light)
    }

    private func activateSearch() {
        guard bottomBarMode != .searchActive else { return }

        AnalyticsManager.shared.logCustomEvent("onboarding_places_search_mode_enter", parameters: [
            "selected_places_count": selectedPlaces.count
        ])

        searchText = ""
        if !appliedSearchText.isEmpty {
            withAnimation(filterResultsAnimation) {
                appliedSearchText = ""
            }
        }

        searchExpansionTask?.cancel()
        isSearchBarExpanded = false

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            bottomBarMode = .searchActive
        }

        searchFieldFocus = .staging

        searchExpansionTask = Task { @MainActor in
            defer { searchExpansionTask = nil }

            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            guard bottomBarMode == .searchActive else { return }

            withAnimation(searchToggleAnimation) {
                isSearchBarExpanded = true
            }

            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            guard bottomBarMode == .searchActive else { return }

            searchFieldFocus = .visible
        }
    }

    private func dismissSearch() {
        guard bottomBarMode == .searchActive else { return }

        AnalyticsManager.shared.logCustomEvent("onboarding_places_search_mode_exit", parameters: [
            "selected_places_count": selectedPlaces.count
        ])

        searchText = ""
        if !appliedSearchText.isEmpty {
            withAnimation(filterResultsAnimation) {
                appliedSearchText = ""
            }
        }
        searchExpansionTask?.cancel()
        searchExpansionTask = nil

        withAnimation(searchToggleAnimation) {
            isSearchBarExpanded = false
            updateBottomBarMode(preserveSearch: false)
        }

        searchFieldFocus = nil
    }

    // MARK: - Accessibility Labels

    private var searchOpenAccessibilityLabel: String {
        "onboarding.favorite_places.search_button.accessibility".localized
    }

    private var searchCloseAccessibilityLabel: String {
        "onboarding.favorite_places.search_close_button.accessibility".localized
    }

    private var clearSearchAccessibilityLabel: String {
        "onboarding.favorite_places.search_clear_button.accessibility".localized
    }
}
