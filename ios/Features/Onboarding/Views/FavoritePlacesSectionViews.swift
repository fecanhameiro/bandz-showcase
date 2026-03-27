//
//  FavoritePlacesSectionViews.swift
//  Bandz
//
//  Section rendering components for FavoritePlacesView.
//  Extracted from OnboardingFavoritePlacesView for maintainability.
//

import SwiftUI

// MARK: - Section Content & Headers

extension OnboardingFavoritePlacesView {

    // MARK: - Section Content Grid

    @ViewBuilder
    func sectionContent(
        for section: PlacesSection,
        places: [Place],
        sectionIndex: Int,
        isFiltering: Bool
    ) -> some View {
        let tileTransition: AnyTransition = isFiltering ? .opacity : .identity

        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: SpacingSystem.Size.md),
            GridItem(.flexible(), spacing: SpacingSystem.Size.md)
        ], spacing: SpacingSystem.Size.md) {
            ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                UnifiedTileView(
                    title: place.name,
                    subtitle: generateSubtitle(for: place),
                    imageName: imageService.generatePlaceImageURL(
                        placeId: place.id,
                        size: .small,
                        type: .profile
                    ),
                    tileType: .place(),
                    actionMode: .selection,
                    isSelected: selectedPlaces.contains(place),
                    isAnimating: animatePlaces,
                    animationDelay: Double(sectionIndex * 10 + index) * 0.05,
                    showDistance: getCurrentUserLocation() != nil,
                    distanceText: place.formattedDistance(to: getCurrentUserLocation())
                ) {
                    togglePlace(place)
                }
                .transition(tileTransition)
            }
        }
        .padding(.horizontal, SpacingSystem.Size.lg)
        .padding(.bottom, SpacingSystem.Size.md)
    }

    // MARK: - Section Header

    // MARK: - Section Header Colors

    private var sectionHeaderTintFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : ColorSystem.Brand.primary.opacity(0.12)
    }

    private var sectionHeaderStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : ColorSystem.Brand.primary.opacity(0.10)
    }

    private var sectionHeaderMaterialSaturation: Double {
        colorScheme == .dark ? 1.0 : 1.8
    }

    private var countBadgeFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)
    }

    private var countBadgeStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.12)
    }

    @ViewBuilder
    func sectionHeader(
        for section: PlacesSection,
        userExpandedGenres: [String] = [],
        visiblePlacesCount: Int? = nil,
        animationDelay: Double = 0
    ) -> some View {
        let displayedCount = visiblePlacesCount ?? section.places.count
        let shape = RoundedRectangle(cornerRadius: SpacingSystem.Size.sm)

        HStack(alignment: .center, spacing: SpacingSystem.Size.sm) {
            Image(systemName: section.isPreferred ? "heart.fill" : "map.fill")
                .font(.system(size: Typography.FontSize.small, weight: .medium))
                .foregroundStyle(ColorSystem.Brand.primary)

            VStack(alignment: .leading, spacing: SpacingSystem.Size.xxxs) {
                Text(section.title)
                    .bodyEmphasized(alignment: .leading)
                    .bandzForegroundStyle(.primary)

                if section.isPreferred && !userExpandedGenres.isEmpty {
                    genresHashtagsView(userExpandedGenres: userExpandedGenres)
                }
            }

            Spacer()

            Text("\(displayedCount)")
                .font(.system(size: Typography.FontSize.xSmall, weight: .semibold))
                .foregroundStyle(ColorSystem.Text.secondary)
                .contentTransition(.numericText())
                .padding(.horizontal, SpacingSystem.Size.xs)
                .padding(.vertical, SpacingSystem.Size.xxxs)
                .background(
                    Capsule().fill(countBadgeFill)
                        .overlay(Capsule().stroke(countBadgeStroke, lineWidth: 0.5))
                )
        }
        .padding(.horizontal, SpacingSystem.Size.md)
        .padding(.vertical, SpacingSystem.Size.sm)
        .background(
            shape.fill(sectionHeaderTintFill)
                .background(shape.fill(.ultraThinMaterial).saturation(sectionHeaderMaterialSaturation))
                .overlay(shape.stroke(sectionHeaderStroke, lineWidth: 0.5))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(animateHeaders ? 1.0 : 0.95)
        .opacity(animateHeaders ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay),
            value: animateHeaders
        )
    }

    // MARK: - Genres Hashtags

    @ViewBuilder
    private func genresHashtagsView(userExpandedGenres: [String]) -> some View {
        let mainGenres = Array(userExpandedGenres.prefix(3))
        let hashtagGenres = mainGenres.map { "#\($0.lowercased())" }

        HStack(spacing: SpacingSystem.Size.xxs) {
            ForEach(Array(hashtagGenres.enumerated()), id: \.element) { _, hashtag in
                Text(hashtag)
                    .hashtag()
                    .foregroundStyle(ColorSystem.Text.secondary)
            }

            if userExpandedGenres.count > 3 {
                let extraCount = userExpandedGenres.count - 3
                Text("+\(extraCount)")
                    .hashtag()
                    .foregroundStyle(ColorSystem.Text.secondary)
            }
        }
    }
}

// MARK: - Glass Circle Button Style

struct GlassCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
