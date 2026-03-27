//
//  StreamingConnectionComponents.swift
//  Bandz
//
//  Created by Claude Code on 09/10/25.
//  Shared UI components for streaming service connection flows
//

import SwiftUI
import UIKit

// MARK: - Animated Music Icon

/// Animated music note icon for connecting phase
/// Shows pulsing animation to indicate ongoing connection
struct AnimatedMusicIcon: View {
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "music.note")
            .font(.system(size: StreamingConnectionConstants.UI.mediumIconSize, weight: .medium))
            .foregroundStyle(color)
            .scaleEffect(isAnimating ? StreamingConnectionConstants.Animation.musicIconScaleMax : StreamingConnectionConstants.Animation.musicIconScaleMin)
            .opacity(isAnimating ? StreamingConnectionConstants.Animation.musicIconOpacityMax : StreamingConnectionConstants.Animation.musicIconOpacityMin)
            .animation(
                .easeInOut(duration: StreamingConnectionConstants.Animation.pulseDuration).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            .accessibilityLabel("Connecting to music service")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Animated Waveform Icon

/// Animated waveform icon for processing phase
/// Shows 5 bars with staggered height animations
struct AnimatedWaveformIcon: View {
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: isAnimating ? StreamingConnectionConstants.Animation.waveformHeights[index] : 8)
                    .animation(
                        .easeInOut(duration: StreamingConnectionConstants.Animation.waveformDuration)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * StreamingConnectionConstants.Animation.waveformDelay),
                        value: isAnimating
                    )
            }
        }
        .frame(height: StreamingConnectionConstants.UI.mediumIconSize)
        .onAppear {
            isAnimating = true
        }
        .accessibilityLabel("Analyzing your music preferences")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Elegant Progress Bar

/// Elegant progress bar component with shimmer effect
struct ElegantProgressBar: View {
    let statusText: String
    let progress: Double
    let color: Color
    let showPercentage: Bool

    init(
        statusText: String,
        progress: Double,
        color: Color,
        showPercentage: Bool = false
    ) {
        self.statusText = statusText
        self.progress = progress
        self.color = color
        self.showPercentage = showPercentage
    }

    var body: some View {
        let progressWidth = max(0, CGFloat(progress) * StreamingConnectionConstants.UI.progressBarWidth)
        let progressHeight = StreamingConnectionConstants.UI.progressBarHeight
        let cornerRadius = StreamingConnectionConstants.UI.progressBarCornerRadius

        return VStack(spacing: SpacingSystem.Size.xs) {
            // Status text with optional percentage
            HStack {
                Text(statusText)
                    .font(.system(size: Typography.FontSize.small, weight: .medium))
                    .bandzForegroundStyle(.secondary)

                if showPercentage {
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: Typography.FontSize.xSmall, weight: .semibold))
                        .foregroundStyle(color)
                }
            }

            // Progress bar container
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ColorSystem.Text.primary.opacity(0.1))
                    .frame(height: progressHeight)

                progressFill(width: progressWidth, height: progressHeight, cornerRadius: cornerRadius)
            }
            .frame(width: StreamingConnectionConstants.UI.progressBarWidth)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(statusText), \(Int(progress * 100)) percent complete")
        .accessibilityValue("\(Int(progress * 100))%")
    }

    private func progressFill(width: CGFloat, height: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(color.opacity(0.8))
            .frame(width: width, height: height)
            .animation(.easeInOut(duration: 0.3), value: progress)
            .overlay(alignment: .leading) {
                if progress > 0 && progress < 1.0 && width > 0 {
                    shimmerOverlay(height: height, cornerRadius: cornerRadius, maxOffset: width)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func shimmerOverlay(height: CGFloat, cornerRadius: CGFloat, maxOffset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        ColorSystem.Text.primary.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: shimmerWidth, height: height)
            .offset(x: shimmerOffset)
            .onAppear {
                startShimmer(maxOffset: maxOffset)
            }
            .onChange(of: maxOffset) { _, newWidth in
                startShimmer(maxOffset: newWidth)
            }
    }

    private func startShimmer(maxOffset: CGFloat) {
        guard maxOffset > 0 else {
            shimmerOffset = -shimmerWidth
            return
        }

        shimmerOffset = -shimmerWidth
        withAnimation(.linear(duration: StreamingConnectionConstants.Animation.shimmerDuration).repeatForever(autoreverses: false)) {
            shimmerOffset = maxOffset
        }
    }

    private let shimmerWidth: CGFloat = 30

    @State private var shimmerOffset: CGFloat = 0
}

// MARK: - Shared Phase Enum

enum StreamingConnectionPhase {
    case initial
    case connecting
    case processing
    case success
    case genreResults
    case error
}

// MARK: - Common Layout

struct StreamingConnectionLayout<ResultsContent: View>: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    let service: StreamingService
    let phase: StreamingConnectionPhase
    let brandColor: Color

    // Initial phase content
    let connectTitle: String
    let connectSubtitle: String
    let connectButtonTitle: String
    let isConnectLoading: Bool
    let onConnect: () -> Void

    // Connecting / processing content
    let connectingTitle: String
    let connectingSubtitle: String
    let processingTitle: String
    let processingSubtitle: String
    let processingStatusText: String
    let processingProgress: Double
    let canCancel: Bool
    let onCancel: () -> Void

    // Success content
    let successTitle: String
    let successSubtitle: String

    // Error content
    let errorTitle: String
    let errorFallbackMessage: String
    let errorRetryTitle: String
    let errorDescriptor: StreamingConnectionErrorDescriptor?
    let onRetry: () -> Void
    let onContinueAfterError: (() -> Void)?

    // Genre results
    let resultsContent: () -> ResultsContent

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, SpacingSystem.Size.lg)
            .padding(.horizontal, SpacingSystem.Size.md)
            .background(serviceTintOverlay)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .initial:
            initialView
        case .connecting:
            connectingView
        case .processing:
            processingView
        case .success:
            successView
        case .genreResults:
            resultsContent()
        case .error:
            errorView
        }
    }

    private var initialView: some View {
        VStack(spacing: SpacingSystem.Size.lg) {
            Image(systemName: "music.note")
                .font(.system(size: StreamingConnectionConstants.UI.largeIconSize))
                .foregroundStyle(brandColor)
                .padding(.bottom, SpacingSystem.Size.md)

            Text(connectTitle)
                .h4()
                .bandzForegroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(connectSubtitle)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .multilineTextAlignment(.center)

            BandzGlassButton(
                connectButtonTitle,
                isLoading: isConnectLoading,
                style: .darkGlass,
                action: onConnect
            )
            .padding(.horizontal, SpacingSystem.Size.md)
            .padding(.top, SpacingSystem.Size.md)
        }
        .padding(.vertical, SpacingSystem.Size.lg)
    }

    private var connectingView: some View {
        VStack(spacing: SpacingSystem.Size.lg) {
            AnimatedMusicIcon(color: brandColor)
                .padding(.bottom, SpacingSystem.Size.sm)

            Text(connectingTitle)
                .h4()
                .bandzForegroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(connectingSubtitle)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ElegantProgressBar(
                statusText: connectingSubtitle,
                progress: StreamingConnectionConstants.Progress.connecting,
                color: brandColor
            )

            cancelButton
        }
        .padding(.vertical, SpacingSystem.Size.lg)
    }

    private var processingView: some View {
        VStack(spacing: SpacingSystem.Size.lg) {
            AnimatedWaveformIcon(color: brandColor)
                .padding(.bottom, SpacingSystem.Size.sm)

            VStack(spacing: SpacingSystem.Size.sm) {
                Text(processingTitle)
                    .h5(alignment: .center)
                    .bandzForegroundStyle(.primary)

                Text(processingSubtitle)
                    .bodyRegular(alignment: .center)
                    .bandzForegroundStyle(.secondary)
                    .opacity(0.7)
            }

            ElegantProgressBar(
                statusText: processingStatusText,
                progress: processingProgress,
                color: brandColor
            )

            cancelButton
        }
        .padding(.vertical, SpacingSystem.Size.lg)
    }

    private var successView: some View {
        VStack(spacing: SpacingSystem.Size.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: StreamingConnectionConstants.UI.successIconSize))
                .foregroundStyle(ColorSystem.Feedback.success)
                .scaleEffect(animatedScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animatedScale)
                .onAppear {
                    animatedScale = StreamingConnectionConstants.Animation.checkmarkBounceScale
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(StreamingConnectionConstants.Timing.checkmarkBounceDelay))
                        animatedScale = 1.0
                    }
                }
                .padding(.bottom, SpacingSystem.Size.sm)
                .accessibilityLabel("Success! Processing complete")

            VStack(spacing: SpacingSystem.Size.sm) {
                Text(successTitle)
                    .h5(alignment: .center)
                    .bandzForegroundStyle(.primary)

                Text(successSubtitle)
                    .bodyRegular(alignment: .center)
                    .bandzForegroundStyle(.secondary)
                    .opacity(0.8)
            }

            ElegantProgressBar(
                statusText: successTitle,
                progress: StreamingConnectionConstants.Progress.completed,
                color: ColorSystem.Feedback.success
            )
        }
        .padding(.vertical, SpacingSystem.Size.lg)
    }

    private var errorView: some View {
        VStack(spacing: SpacingSystem.Size.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: StreamingConnectionConstants.UI.errorIconSize))
                .foregroundStyle(ColorSystem.System.error)
                .padding(.bottom, SpacingSystem.Size.md)

            Text(errorTitle)
                .h4()
                .bandzForegroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let descriptor = errorDescriptor {
                VStack(spacing: SpacingSystem.Size.xs) {
                    Text(descriptor.message)
                        .bodyRegular(alignment: .center)
                        .bandzForegroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let suggestion = descriptor.suggestion {
                        Text(suggestion)
                            .footnote(alignment: .center)
                            .bandzForegroundStyle(.secondary)
                            .opacity(0.8)
                    }
                }
            } else {
                Text(errorFallbackMessage)
                    .bodyRegular(alignment: .center)
                    .bandzForegroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: SpacingSystem.Size.md) {
                if errorDescriptor?.allowsRetry ?? true {
                    BandzGlassButton(
                        errorRetryTitle,
                        style: .darkGlass,
                        action: onRetry
                    )
                    .padding(.horizontal, SpacingSystem.Size.md)
                }

                if let continueAction = onContinueAfterError {
                    BandzGlassButton(
                        "common.skip_for_now".localized,
                        style: isRetryHidden ? .darkGlass : .medium,
                        action: continueAction
                    )
                    .padding(.horizontal, SpacingSystem.Size.md)
                    .padding(.top, isRetryHidden ? 0 : SpacingSystem.Size.xs)
                }
            }
            .padding(.top, SpacingSystem.Size.md)
        }
        .padding(.vertical, SpacingSystem.Size.lg)
    }

    private var isRetryHidden: Bool {
        !(errorDescriptor?.allowsRetry ?? true)
    }

    private var cancelButton: some View {
        BandzGlassButton(
            "common.cancel".localized,
            style: .medium,
            action: onCancel
        )
        .disabled(!canCancel)
        .opacity(canCancel ? 1.0 : 0.6)
        .padding(.horizontal, SpacingSystem.Size.md)
        .padding(.top, SpacingSystem.Size.md)
    }

    private var serviceTintOverlay: some View {
        RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
            .fill(
                LinearGradient(
                    colors: [
                        brandColor.opacity(colorScheme == .dark ? 0.06 : 0.04),
                        brandColor.opacity(colorScheme == .dark ? 0.02 : 0.01)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .allowsHitTesting(false)
    }

    @State private var animatedScale: CGFloat = 0.8
}

// MARK: - Error Descriptor

/// Generic error descriptor for streaming service connection failures
struct StreamingConnectionErrorDescriptor: Equatable {
    let message: String
    let suggestion: String?
    let allowsContinue: Bool
    let allowsRetry: Bool
    let analyticsValue: String

    // MARK: - Generic Factories

    static func authenticationCancelled(service: String) -> Self {
        return StreamingConnectionErrorDescriptor(
            message: "\(service.lowercased()).auth_cancelled".localized,
            suggestion: nil,
            allowsContinue: true,
            allowsRetry: true,
            analyticsValue: "auth_cancelled"
        )
    }

    static func networkError(service: String) -> Self {
        return StreamingConnectionErrorDescriptor(
            message: "\(service.lowercased()).network_error".localized,
            suggestion: nil,
            allowsContinue: false,
            allowsRetry: true,
            analyticsValue: "network_error"
        )
    }

    static func timeout(service: String) -> Self {
        return StreamingConnectionErrorDescriptor(
            message: "\(service.lowercased()).timeout_message".localized,
            suggestion: "notifications.error.timeout".localized,
            allowsContinue: true,
            allowsRetry: true,
            analyticsValue: "timeout"
        )
    }

    static func genericError(service: String) -> Self {
        return StreamingConnectionErrorDescriptor(
            message: "\(service.lowercased()).generic_error".localized,
            suggestion: nil,
            allowsContinue: false,
            allowsRetry: true,
            analyticsValue: "unknown"
        )
    }

    // MARK: - Spotify Specific

    static func makeForSpotify(error: Error) -> StreamingConnectionErrorDescriptor {
        if let processingError = error as? SpotifyProcessingError {
            switch processingError {
            case .timeout:
                return timeout(service: "Spotify")
            case .userNotFound:
                return StreamingConnectionErrorDescriptor(
                    message: "spotify.connection_error".localized,
                    suggestion: processingError.recoverySuggestion,
                    allowsContinue: false,
                    allowsRetry: true,
                    analyticsValue: "user_not_found"
                )
            default:
                return StreamingConnectionErrorDescriptor(
                    message: "spotify.generic_error".localized,
                    suggestion: processingError.recoverySuggestion,
                    allowsContinue: false,
                    allowsRetry: true,
                    analyticsValue: "processing_error"
                )
            }
        }

        if let authError = error as? SpotifyAuthError {
            switch authError {
            case .authenticationCancelled:
                return authenticationCancelled(service: "Spotify")
            case .appNotInstalled:
                return StreamingConnectionErrorDescriptor(
                    message: "spotify.no_internet".localized,
                    suggestion: nil,
                    allowsContinue: false,
                    allowsRetry: true,
                    analyticsValue: "app_not_installed"
                )
            case .networkError:
                return networkError(service: "Spotify")
            default:
                return StreamingConnectionErrorDescriptor(
                    message: "spotify.connection_error".localized,
                    suggestion: nil,
                    allowsContinue: false,
                    allowsRetry: true,
                    analyticsValue: "auth_error"
                )
            }
        }

        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return networkError(service: "Spotify")
        }

        return genericError(service: "Spotify")
    }

    // MARK: - Apple Music Specific

    static func makeForAppleMusic(error: Error) -> StreamingConnectionErrorDescriptor {
        if let appleError = error as? AppleMusicServiceError {
            switch appleError {
            case .processingTimeout:
                return timeout(service: "AppleMusic")
            case .processingIncomplete:
                return StreamingConnectionErrorDescriptor(
                    message: "applemusic.generic_error".localized,
                    suggestion: "notifications.error.timeout".localized,
                    allowsContinue: true,
                    allowsRetry: true,
                    analyticsValue: "processing_incomplete"
                )
            case .musicKitUnavailable:
                return StreamingConnectionErrorDescriptor(
                    message: "applemusic.generic_error".localized,
                    suggestion: "MusicKit is not available on this device or OS version".localized,
                    allowsContinue: false,
                    allowsRetry: true,
                    analyticsValue: "musickit_unavailable"
                )
            case .authorizationFailed(let status):
                if status == .denied {
                    return authenticationCancelled(service: "AppleMusic")
                }
                if status == .restricted {
                    return StreamingConnectionErrorDescriptor(
                        message: "applemusic.subscription_required".localized,
                        suggestion: "Check if Apple Music is restricted by parental controls on this device.",
                        allowsContinue: true,
                        allowsRetry: true,
                        analyticsValue: "authorization_restricted"
                    )
                }
            case .authenticationFailed:
                return StreamingConnectionErrorDescriptor(
                    message: "applemusic.connection_failed".localized,
                    suggestion: "applemusic.generic_error".localized,
                    allowsContinue: false,
                    allowsRetry: true,
                    analyticsValue: "auth_failed"
                )
            }
        }

        // Check for AppleMusicAuthHelper.AuthError
        let errorDescription = error.localizedDescription.lowercased()

        if errorDescription.contains("denied") || errorDescription.contains("authorization was denied") {
            return authenticationCancelled(service: "AppleMusic")
        }

        if errorDescription.contains("restricted") || errorDescription.contains("authorization is restricted") {
            return StreamingConnectionErrorDescriptor(
                message: "applemusic.subscription_required".localized,
                suggestion: "Check if Apple Music is restricted by parental controls on this device".localized,
                allowsContinue: false,
                allowsRetry: true,
                analyticsValue: "restricted"
            )
        }

        if errorDescription.contains("musickit") || errorDescription.contains("not available") {
            return StreamingConnectionErrorDescriptor(
                message: "applemusic.generic_error".localized,
                suggestion: "MusicKit is not available on this device or OS version".localized,
                allowsContinue: false,
                allowsRetry: true,
                analyticsValue: "musickit_unavailable"
            )
        }

        if errorDescription.contains("timeout") || errorDescription.contains("timed out") {
            return timeout(service: "AppleMusic")
        }

        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return networkError(service: "AppleMusic")
        }

        return genericError(service: "AppleMusic")
    }
}

// MARK: - Haptic Feedback

/// Haptic feedback helper for streaming connection flows
@MainActor
enum HapticFeedback {

    /// Trigger success haptic (medium impact)
    static func success() {
        HapticManager.shared.impact(style: .medium)
    }

    /// Trigger error haptic (notification error)
    static func error() {
        HapticManager.shared.notify(.error)
    }

    /// Trigger cancel haptic (light impact)
    static func cancel() {
        HapticManager.shared.impact(style: .light)
    }

    /// Trigger selection haptic (selection feedback)
    static func selection() {
        HapticManager.shared.selection()
    }
}
