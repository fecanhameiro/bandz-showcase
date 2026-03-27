//
//  MusicGenresPieChart.swift
//  Bandz
//
//  Created by Claude on 24/07/25.
//

import SwiftUI
import Charts

// MARK: - Music Genres Pie Chart
struct MusicGenresPieChart: View {
    let genres: [UserGenreDataEntry]
    @State private var animateChart = false

    var body: some View {
        VStack(spacing: SpacingSystem.Size.lg) {

            // Donut chart with Swift Charts
            Chart(genres) { genre in
                SectorMark(
                    angle: .value("Percentage", animateChart ? genre.percentage : 0),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(genre.colorValue)
                .cornerRadius(4)
            }
            .chartLegend(.hidden)
            .frame(width: 200, height: 200)
            .overlay {
                VStack(spacing: SpacingSystem.Size.xxxs) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: Typography.FontSize.medium, weight: .medium))
                        .bandzForegroundStyle(.secondary)
                    Text("\(genres.count)")
                        .font(.system(size: Typography.FontSize.xLarge, weight: .bold))
                        .bandzForegroundStyle(.primary)
                    Text("spotify.genres_count_label".localized)
                        .footnote()
                        .bandzForegroundStyle(.secondary)
                }
                .opacity(animateChart ? 1.0 : 0.0)
            }
            .scaleEffect(animateChart ? 1.0 : 0.8)

            // Legend
            GenreLegendView(genres: genres)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animateChart = true
            }
        }
    }
}
