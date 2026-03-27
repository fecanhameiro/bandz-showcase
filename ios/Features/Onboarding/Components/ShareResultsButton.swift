//
//  ShareResultsButton.swift
//  Bandz
//
//  Created by Claude on 24/07/25.
//

import SwiftUI

// MARK: - Share Results Button
struct ShareResultsButton: View {
    let service: StreamingService
    let genres: [UserGenreDataEntry]
    @State private var isRendering = false
    @State private var animateGlow = false
    @State private var shareTask: Task<Void, Never>?

    private var canShare: Bool {
        !genres.isEmpty && !isRendering && shareTask == nil
    }

    var body: some View {
        Button(action: startShare) {
            HStack(spacing: SpacingSystem.Size.sm) {
                if isRendering {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.92)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: Typography.FontSize.body, weight: .semibold))
                }

                Text(isRendering ? "share.generating_card".localized : "spotify.share_discoveries".localized)
                    .font(.system(size: Typography.FontSize.body, weight: .bold))

                if !isRendering {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: Typography.FontSize.small, weight: .semibold))
                        .opacity(0.85)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, SpacingSystem.Size.lg)
            .padding(.vertical, SpacingSystem.Size.sm)
            .background(
                RoundedRectangle(cornerRadius: SpacingSystem.Size.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                service.adaptiveBrandColor(for: .dark).opacity(0.96),
                                ColorSystem.Brand.primary.opacity(0.94)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: SpacingSystem.Size.md, style: .continuous)
                            .stroke(.white.opacity(0.26), lineWidth: 1)
                    )
            )
            .shadow(color: service.adaptiveBrandColor(for: .dark).opacity(animateGlow ? 0.55 : 0.25), radius: animateGlow ? 16 : 8, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!canShare)
        .opacity(canShare ? 1 : 0.7)
        .scaleEffect(isRendering ? 0.985 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isRendering)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
        .onDisappear {
            shareTask?.cancel()
            shareTask = nil
            isRendering = false
        }
    }

    private func startShare() {
        guard canShare else { return }

        withAnimation(.easeInOut(duration: 0.15)) {
            isRendering = true
        }

        HapticManager.shared.impact(style: .light)
        AnalyticsManager.shared.logCustomEvent(
            "onboarding_genre_results_share_tapped",
            parameters: [
                "service_id": service.id,
                "service_name": service.name,
                "genres_count": genres.count
            ]
        )

        shareTask = Task {
            await MusicInsightsShareActionHandler.handle(
                genres: genres,
                service: service,
                setRendering: { value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRendering = value
                    }
                }
            )

            await MainActor.run {
                shareTask = nil
            }
        }
    }
}
