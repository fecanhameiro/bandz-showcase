//
//  GenreResultsList.swift
//  Bandz
//
//  Created by Claude on 24/07/25.
//

import SwiftUI

// MARK: - Genre Results List
struct GenreResultsList: View {
    let genres: [UserGenreDataEntry]
    @State private var animateList = false

    var body: some View {
        VStack(spacing: SpacingSystem.Size.xs) {

            HStack(spacing: SpacingSystem.Size.xs) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: Typography.FontSize.small))
                    .foregroundStyle(ColorSystem.Brand.primarySoft)

                Text("spotify.genre_details_title".localized)
                    .bodyEmphasized(alignment: .leading)
                    .bandzForegroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(genres.enumerated()), id: \.element.id) { index, genre in
                GenreResultRow(genre: genre)
                    .opacity(animateList ? 1.0 : 0.0)
                    .offset(x: animateList ? 0 : 20)
                    .scaleEffect(animateList ? 1.0 : 0.95)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(Double(index) * 0.08),
                        value: animateList
                    )
            }
        }
        .onAppear {
            withAnimation {
                animateList = true
            }
        }
    }
}

// MARK: - Genre Result Row
struct GenreResultRow: View {
    let genre: UserGenreDataEntry
    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    private let iconSize: CGFloat = 44
    private let iconImageSize: CGFloat = 34

    var body: some View {
        HStack(spacing: SpacingSystem.Size.sm) {

            // Genre icon with colored tint background
            ZStack {
                Circle()
                    .fill(genre.colorValue.opacity(colorScheme == .dark ? 0.15 : 0.10))
                    .frame(width: iconSize, height: iconSize)

                StyleGroupIconManager.loadIcon(named: genre.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconImageSize, height: iconImageSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(genre.colorValue, lineWidth: 2.5)
                    )
            }

            // Content section with colored accent bar
            HStack {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(genre.colorValue)
                    .frame(width: 5)
                    .shadow(color: colorScheme == .dark ? genre.colorValue.opacity(0.4) : .clear, radius: 4)

                VStack(alignment: .leading, spacing: SpacingSystem.Size.xxxs) {
                    Text(genre.mainGenre)
                        .bodyEmphasized(alignment: .leading)
                        .bandzForegroundStyle(.primary)

                    Text(String(format: "spotify.preferences_percentage".localized, genre.percentage))
                        .footnote()
                        .foregroundStyle(ColorSystem.Text.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(genre.score.formatted(.number))
                        .bodyEmphasized(alignment: .trailing)
                        .bandzForegroundStyle(.primary)

                    Text("spotify.points".localized)
                        .micro()
                        .foregroundStyle(ColorSystem.Text.secondary)
                }
                .alignmentGuide(.firstTextBaseline) { d in d[.top] }
            }
            .padding(.horizontal, SpacingSystem.Size.sm)
            .padding(.vertical, SpacingSystem.Size.xs)
            .background(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.standard, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.standard, style: .continuous)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15), lineWidth: 0.5)
                    )
            )
        }
    }
}
