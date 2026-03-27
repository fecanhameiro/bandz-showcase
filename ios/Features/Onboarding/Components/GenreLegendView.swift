//
//  GenreLegendView.swift
//  Bandz
//
//  Created by Claude on 24/07/25.
//

import SwiftUI

// MARK: - Genre Legend View
struct GenreLegendView: View {
    let genres: [UserGenreDataEntry]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: SpacingSystem.Size.sm) {
            ForEach(genres) { genre in
                HStack(spacing: SpacingSystem.Size.xs) {
                    Circle()
                        .fill(genre.colorValue)
                        .frame(width: Typography.FontSize.micro, height: Typography.FontSize.micro)

                    Text(genre.mainGenre)
                        .font(.system(size: Typography.FontSize.xSmall, weight: .semibold))
                        .bandzForegroundStyle(.primary)

                    Text("\(genre.percentage)%")
                        .footnote()
                        .foregroundStyle(ColorSystem.Text.secondary)

                    Spacer()
                }
            }
        }
        .padding(.horizontal, SpacingSystem.Size.md)
    }
}