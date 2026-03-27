//
//  SpotifyConnectionContent.swift
//  Bandz
//
//  Created by Claude Code on 25/07/25.
//  Complete Spotify flow including processing and genre results
//

import Foundation
import SwiftUI
import Combine

// MARK: - Spotify Connection Content
/// Complete Spotify flow: connection → processing → genre results
/// Self-contained component that handles entire Spotify experience
struct SpotifyConnectionContent: View {
    let service: StreamingService
    let onComplete: (_ hasDiscoveredGenres: Bool) -> Void
    let onCancel: () -> Void
    let onCloseButtonVisibilityChanged: (Bool) -> Void
    let onProcessingStateChanged: (Bool) -> Void
    let onSuccessStateChanged: (Bool) -> Void
    let onErrorStateChanged: (Bool) -> Void

    private let spotifyIntegrationService: SpotifyIntegrationServiceProtocol
    private let userDataManager: UserDataManager
    @Inject private var logger: Logger
    private let loggingContext = "Onboarding.Streaming.Spotify"

    @State private var syncStatus: SpotifyServiceSyncStatus = .idle
    @State private var processedGenres: ProcessedGenreData?
    @State private var currentPhase: StreamingConnectionPhase = .initial
    @State private var connectionTask: Task<Void, Never>?
    @State private var transitionTask: Task<Void, Never>?
    @State private var errorDescriptor: StreamingConnectionErrorDescriptor?
    @State private var statusListenerTask: Task<Void, Never>?
    @State private var retryCount: Int = 0

    private var shouldShowCloseButton: Bool {
        switch currentPhase {
        case .initial, .error:
            return true
        case .connecting, .processing, .success, .genreResults:
            return false
        }
    }

    private var isInProcessingState: Bool {
        switch currentPhase {
        case .connecting, .processing:
            return true
        case .initial, .success, .genreResults, .error:
            return false
        }
    }

    private var isInSuccessState: Bool {
        currentPhase == .success
    }

    private var isConnectionInProgress: Bool {
        currentPhase == .connecting || currentPhase == .processing
    }

    init(
        service: StreamingService,
        onComplete: @escaping (_ hasDiscoveredGenres: Bool) -> Void,
        onCancel: @escaping () -> Void,
        onCloseButtonVisibilityChanged: @escaping (Bool) -> Void,
        onProcessingStateChanged: @escaping (Bool) -> Void,
        onSuccessStateChanged: @escaping (Bool) -> Void,
        onErrorStateChanged: @escaping (Bool) -> Void,
        spotifyIntegrationService: SpotifyIntegrationServiceProtocol? = nil,
        userDataManager: UserDataManager? = nil
    ) {
        self.service = service
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onCloseButtonVisibilityChanged = onCloseButtonVisibilityChanged
        self.onProcessingStateChanged = onProcessingStateChanged
        self.onSuccessStateChanged = onSuccessStateChanged
        self.onErrorStateChanged = onErrorStateChanged
        self.spotifyIntegrationService = spotifyIntegrationService ?? DIContainer.shared.resolveSafe(SpotifyIntegrationServiceProtocol.self)
        self.userDataManager = userDataManager ?? DIContainer.shared.resolveSafe(UserDataManager.self)
    }
    
    var body: some View {
        StreamingConnectionLayout(
            service: service,
            phase: currentPhase,
            brandColor: adaptiveServiceColor,
            connectTitle: String(format: "spotify.connect_to_service".localized, service.name),
            connectSubtitle: "spotify.connection_description".localized,
            connectButtonTitle: "spotify.connect_now".localized,
            isConnectLoading: isConnectionInProgress,
            onConnect: startConnectionFlow,
            connectingTitle: String(format: "spotify.connecting".localized, service.name),
            connectingSubtitle: "spotify.authorize_access".localized,
            processingTitle: "spotify.analyzing_preferences".localized,
            processingSubtitle: "spotify.discovering_genres".localized,
            processingStatusText: syncStatusText,
            processingProgress: syncProgress,
            canCancel: connectionTask != nil,
            onCancel: { cancelConnectionFlow() },
            successTitle: "spotify.status_complete".localized,
            successSubtitle: "spotify.discovering_genres".localized,
            errorTitle: "spotify.connection_failed".localized,
            errorFallbackMessage: "spotify.generic_error".localized,
            errorRetryTitle: "spotify.retry".localized,
            errorDescriptor: errorDescriptor,
            onRetry: startConnectionFlow,
            onContinueAfterError: continueAfterErrorHandler,
            resultsContent: { AnyView(genreResultsView) }
        )
        .onAppear {
            log(.info, "Spotify streaming dialog appeared")
            onCloseButtonVisibilityChanged(shouldShowCloseButton)
            startStatusListener()
        }
        .onDisappear {
            log(.debug, "Spotify streaming dialog disappeared")
            statusListenerTask?.cancel()
            statusListenerTask = nil
            if currentPhase == .connecting || currentPhase == .processing {
                cancelConnectionFlow(resetPhase: false)
            }
        }
        .onChange(of: currentPhase) { previousPhase, newPhase in
            log(.debug, "Phase changed", metadata: [
                "previous_phase": phaseName(previousPhase),
                "new_phase": phaseName(newPhase)
            ])
            // Update close button visibility when phase changes
            onCloseButtonVisibilityChanged(shouldShowCloseButton)
            
            // Update processing state for shimmer
            onProcessingStateChanged(isInProcessingState)
            
            // Update success state for green dialog
            onSuccessStateChanged(isInSuccessState)

            // Update error state for red dialog
            onErrorStateChanged(newPhase == .error)

            if newPhase != .error {
                errorDescriptor = nil
            }

            if newPhase == .initial {
                processedGenres = nil
            }
        }
    }

    private var continueAfterErrorHandler: (() -> Void)? {
        guard errorDescriptor?.allowsContinue == true else { return nil }
        return { continueAfterRecoverableError() }
    }

    // MARK: - Genre Results View

    private var hasGenreResults: Bool {
        guard let genres = processedGenres?.genres else { return false }
        return !genres.isEmpty
    }

    private var genreResultsView: some View {
        VStack(spacing: SpacingSystem.Size.sm) {
            if hasGenreResults {
                // Fixed Header - Title
                VStack(spacing: SpacingSystem.Size.xs) {
                    Text("spotify.discovered_genres_title".localized)
                        .h5(alignment: .center)
                        .bandzForegroundStyle(.primary)

                    Text("spotify.based_on_library".localized)
                        .bodyRegular(alignment: .center)
                        .bandzForegroundStyle(.secondary)
                        .opacity(0.8)
                }
                .padding(.top, SpacingSystem.Size.sm)

                // Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: SpacingSystem.Size.lg) {
                        if let genres = processedGenres?.genres {
                            MusicGenresPieChart(genres: genres)
                                .padding(.top, SpacingSystem.Size.sm)

                            GenreResultsList(genres: genres)
                                .padding(.horizontal, SpacingSystem.Size.xs)

                            ShareResultsButton(service: service, genres: genres)
                        }
                    }
                    .padding(.vertical, SpacingSystem.Size.xs)
                }
                .clipped()
            } else {
                // Empty state — no genres discovered
                Spacer()
                genreEmptyStateView
                Spacer()
            }

            // Continue Button — pinned outside scroll
            BandzGlassButton(
                "spotify.continue".localized,
                style: .darkGlass,
                action: { [hasGenreResults] in
                    AnalyticsManager.shared.logCustomEvent("onboarding_genre_results_continue")

                    onCancel()

                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        onComplete(hasGenreResults)
                    }
                }
            )
            .padding(.horizontal, SpacingSystem.Size.md)
            .padding(.bottom, SpacingSystem.Size.sm)
        }
        .padding(.vertical, SpacingSystem.Size.xs)
    }

    private var genreEmptyStateView: some View {
        VStack(spacing: SpacingSystem.Size.lg) {
            Image(systemName: "music.mic.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(ColorSystem.Brand.primarySoft)
                .symbolEffect(.pulse.byLayer, options: .repeating)

            VStack(spacing: SpacingSystem.Size.xs) {
                Text("streaming.no_genres_title".localized)
                    .h5(alignment: .center)
                    .bandzForegroundStyle(.primary)

                Text("streaming.no_genres_message".localized)
                    .bodyRegular(alignment: .center)
                    .bandzForegroundStyle(.secondary)
                    .opacity(0.8)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, SpacingSystem.Size.lg)
        }
    }
    
    // MARK: - Spotify Integration Methods
    
    @MainActor
    private func startConnectionFlow() {
        guard connectionTask == nil else {
            log(.warning, "Ignoring Spotify connection request because a task is already running")
            return
        }

        // Check retry limit
        guard retryCount < StreamingConnectionConstants.Retry.maxAttempts else {
            log(.error, "Maximum Spotify retry attempts reached", metadata: [
                "max_attempts": StreamingConnectionConstants.Retry.maxAttempts
            ])
            errorDescriptor = StreamingConnectionErrorDescriptor(
                message: "streaming.max_retries_message".localized,
                suggestion: nil,
                allowsContinue: true,
                allowsRetry: false,
                analyticsValue: "max_retries_reached"
            )
            withAnimation(.spring(
                response: StreamingConnectionConstants.Timing.springResponse,
                dampingFraction: StreamingConnectionConstants.Timing.springDamping
            )) {
                currentPhase = .error
            }
            return
        }

        errorDescriptor = nil
        processedGenres = nil
        syncStatus = .syncing
        log(.info, "Starting Spotify connection flow", metadata: [
            "retry_attempt": retryCount
        ])
        connectionTask = Task { await runConnectionFlow() }
    }

    @MainActor
    private func runConnectionFlow() async {
        let startTime = Date()
        log(.info, "Running Spotify connection flow", metadata: [
            "retry_attempt": retryCount
        ])

        AnalyticsManager.shared.logCustomEvent("spotify_processing_started", parameters: [
            "service": service.id,
            "retry_attempt": retryCount
        ])

        defer {
            connectionTask = nil
        }

        transitionTask?.cancel()
        transitionTask = nil

        withAnimation(.spring(
            response: StreamingConnectionConstants.Timing.springResponse,
            dampingFraction: StreamingConnectionConstants.Timing.springDamping
        )) {
            currentPhase = .connecting
        }
        log(.debug, "Spotify connection phase set to connecting")

        do {
            log(.debug, "Collecting data and awaiting Spotify processing")
            let processedData = try await spotifyIntegrationService.collectDataAndAwaitProcessing()
            if Task.isCancelled {
                log(.warning, "Spotify connection flow cancelled after data collection")
                return
            }

            let duration = Date().timeIntervalSince(startTime)

            processedGenres = processedData
            updateUserDataManagerWithSpotifyGenres(processedData)
            syncStatus = .completed

            showSuccessThenResults()
            log(.info, "Spotify processing completed", metadata: [
                "duration_ms": Int(duration * 1000),
                "genres_count": processedData.genres.count,
                "top_genre": processedData.genres.first?.mainGenre ?? "unknown",
                "top_genres": Array(processedData.genres.prefix(5).map { $0.mainGenre }),
                "last_updated": processedData.lastUpdated,
                "source": processedData.source
            ])

            AnalyticsManager.shared.logCustomEvent("spotify_processing_completed", parameters: [
                "service": service.id,
                "genres_count": processedData.genres.count,
                "duration_seconds": Int(duration),
                "top_genre": processedData.genres.first?.mainGenre ?? "unknown",
                "retry_count": retryCount
            ])
        } catch is CancellationError {
            syncStatus = .idle
            withAnimation(.spring(
                response: StreamingConnectionConstants.Timing.springResponse,
                dampingFraction: StreamingConnectionConstants.Timing.springDamping
            )) {
                currentPhase = .initial
            }
            log(.warning, "Spotify connection flow cancelled", metadata: [
                "elapsed_ms": Int(Date().timeIntervalSince(startTime) * 1000)
            ])
            spotifyIntegrationService.clearCache()
            AnalyticsManager.shared.logCustomEvent("spotify_processing_cancelled", parameters: [
                "service": service.id,
                "retry_count": retryCount
            ])
        } catch {
            handleConnectionError(error, source: "run_flow")
        }
    }

    @MainActor
    private func showSuccessThenResults() {
        transitionTask?.cancel()

        // Haptic feedback for success
        HapticFeedback.success()
        log(.info, "Spotify connection flow marked as success")

        withAnimation(.spring(
            response: StreamingConnectionConstants.Timing.springResponse,
            dampingFraction: StreamingConnectionConstants.Timing.springDamping
        )) {
            currentPhase = .success
        }

        transitionTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(StreamingConnectionConstants.Timing.successToResultsDelay))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(
                response: StreamingConnectionConstants.Timing.springResponse,
                dampingFraction: StreamingConnectionConstants.Timing.springDamping
            )) {
                currentPhase = .genreResults
            }
            log(.info, "Spotify connection presenting genre results")
        }
    }

    @MainActor
    private func cancelConnectionFlow(resetPhase: Bool = true) {
        let hadActiveTask = connectionTask != nil
        log(.warning, "Cancelling Spotify connection flow", metadata: [
            "reset_phase": resetPhase,
            "had_active_task": hadActiveTask
        ])

        // Haptic feedback for cancellation
        HapticFeedback.cancel()

        connectionTask?.cancel()
        connectionTask = nil
        transitionTask?.cancel()
        transitionTask = nil
        syncStatus = .idle
        log(.debug, "Spotify sync status reset to idle")
        if resetPhase {
            withAnimation(.spring(
                response: StreamingConnectionConstants.Timing.springResponse,
                dampingFraction: StreamingConnectionConstants.Timing.springDamping
            )) {
                currentPhase = .initial
            }
            log(.debug, "Spotify connection flow reset to initial state")
        }
        if !hadActiveTask {
            spotifyIntegrationService.clearCache()
            log(.debug, "Spotify cache cleared after cancellation")
        }
    }

    @MainActor
    private func handleConnectionError(_ error: Error, source: String = "run_flow") {
        transitionTask?.cancel()
        transitionTask = nil
        retryCount += 1
        errorDescriptor = StreamingConnectionErrorDescriptor.makeForSpotify(error: error)
        let descriptorValue = errorDescriptor?.analyticsValue ?? "unknown"
        logError(error, message: "Spotify connection flow failed", extra: [
            "source": source,
            "descriptor": descriptorValue
        ])

        // Haptic feedback for error
        HapticFeedback.error()

        withAnimation(.spring(
            response: StreamingConnectionConstants.Timing.springResponse,
            dampingFraction: StreamingConnectionConstants.Timing.springDamping
        )) {
            currentPhase = .error
        }

        AnalyticsManager.shared.logCustomEvent("spotify_processing_failed", parameters: [
            "service": service.id,
            "error": error.localizedDescription,
            "retry_count": retryCount
        ])
    }

    @MainActor
    private func updatePhaseForSyncStatus(_ status: SpotifyServiceSyncStatus) {
        switch status {
        case .idle, .completed:
            break
        case .syncing:
            if currentPhase != .connecting {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                    currentPhase = .connecting
                }
            }
        case .processing:
            if currentPhase != .processing {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                    currentPhase = .processing
                }
            }
        case .failed(let error):
            handleConnectionError(error, source: "status_listener")
        }
    }

    @MainActor
    private func startStatusListener() {
        statusListenerTask?.cancel()
        statusListenerTask = Task {
            for await status in spotifyIntegrationService.syncStatusPublisher.values {
                await MainActor.run {
                    syncStatus = status
                    var statusMetadata: [String: Any] = [
                        "status": statusName(status)
                    ]
                    if case .failed(let error) = status {
                        statusMetadata["status_error"] = String(describing: error)
                        statusMetadata["status_error_localized"] = error.localizedDescription
                    }
                    log(.debug, "Received Spotify sync status update", metadata: statusMetadata)
                    updatePhaseForSyncStatus(status)
                }
            }
        }
    }

    @MainActor
    private func continueAfterRecoverableError() {
        log(.warning, "Continuing Spotify onboarding after recoverable error", metadata: [
            "error_reason": errorDescriptor?.analyticsValue ?? "unknown"
        ])
        AnalyticsManager.shared.logCustomEvent("spotify_processing_continued_after_error", parameters: [
            "service": service.id,
            "reason": errorDescriptor?.analyticsValue ?? "unknown",
            "retry_count": retryCount
        ])

        cancelConnectionFlow(resetPhase: true)
        onCancel()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(StreamingConnectionConstants.Timing.dialogCloseDelay))
            onComplete(false)
        }
    }
    
    // MARK: - Computed Properties
    
    private var adaptiveServiceColor: Color {
        service.adaptiveBrandColor(for: colorScheme)
    }
    
    
    private var syncStatusText: String {
        switch syncStatus {
            case .idle:
                return "spotify.status_preparing".localized
            case .syncing:
                return "spotify.status_collecting".localized
            case .processing:
                return "spotify.status_processing".localized
            case .completed:
                return "spotify.status_complete".localized
            case .failed:
                return "spotify.status_failed".localized
        }
    }
    
    private var syncProgress: Double {
        switch syncStatus {
            case .idle:
                return 0.0
            case .syncing:
                return StreamingConnectionConstants.Progress.collecting
            case .processing:
                return StreamingConnectionConstants.Progress.processing
            case .completed:
                return StreamingConnectionConstants.Progress.completed
            case .failed:
                return 0.0
        }
    }
    
    // MARK: - Neutral Color System (State-Agnostic)
    
    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    // MARK: - UserDataManager Integration
    
    /// Updates UserDataManager with genres discovered from Spotify processing
    /// This ensures Places screen can prioritize venues based on user's music taste
    private func updateUserDataManagerWithSpotifyGenres(_ processedData: ProcessedGenreData) {
        log(.info, "Applying Spotify genres to user profile", metadata: [
            "genres_count": processedData.genres.count,
            "top_genre": processedData.genres.first?.mainGenre ?? "unknown"
        ])

        let musicGenres = processedData.genres.map { genreData in
            MusicGenre(
                id: genreData.id,
                name: genreData.mainGenre,
                icon: genreData.icon,
                color: genreData.color,
                isSelected: true
            )
        }

        userDataManager.updateGenres(musicGenres)
        log(.debug, "Spotify genres applied to user data", metadata: [
            "genres": musicGenres.map { $0.name },
            "genre_ids": musicGenres.map { $0.id }
        ])

        AnalyticsManager.shared.logCustomEvent("spotify_genres_applied_to_user_preferences", parameters: [
            "genres_count": musicGenres.count,
            "top_genres": Array(musicGenres.prefix(5)).map { $0.name }
        ])
    }

    // MARK: - Logging

    private func log(_ level: LogLevel, _ message: String, metadata: [String: Any] = [:]) {
        let combinedMetadata = baseMetadata(extra: metadata)
        logger.log(level: level, message: message, metadata: combinedMetadata, context: loggingContext)
    }

    private func logError(_ error: Error, message: String, extra: [String: Any] = [:]) {
        var metadata = errorMetadata(for: error, extra: extra)
        metadata["error.context"] = message
        logger.log(error: error, metadata: metadata, context: loggingContext)
    }

    private func baseMetadata(extra: [String: Any] = [:]) -> [String: Any] {
        var metadata: [String: Any] = [
            "feature": "Onboarding",
            "screen": "StreamingSelection",
            "service": service.id,
            "retry_attempt": retryCount,
            "phase": phaseName(currentPhase),
            "sync_status": statusName(syncStatus),
            "tags": ["Streaming", "Onboarding", service.id]
        ]

        for (key, value) in extra {
            metadata[key] = value
        }

        return metadata
    }

    private func errorMetadata(for error: Error, extra: [String: Any] = [:]) -> [String: Any] {
        var metadata = baseMetadata(extra: extra)
        metadata["error.raw"] = String(describing: error)

        if let nsError = error as NSError?, !nsError.userInfo.isEmpty {
            let userInfoDescription = nsError.userInfo.map { key, value in "\(key)=\(value)" }.joined(separator: " | ")
            metadata["error.userInfo"] = userInfoDescription
        }

        if let spotifyError = error as? SpotifyServiceError {
            metadata["spotify.error"] = String(describing: spotifyError)
            switch spotifyError {
            case .httpError(let statusCode):
                metadata["spotify.http_status"] = statusCode
            case .decodingError(let innerError):
                metadata["spotify.decoding_error"] = String(describing: innerError)
                metadata["spotify.decoding_error_localized"] = innerError.localizedDescription
            default:
                break
            }
        }

        if let processingError = error as? SpotifyProcessingError {
            metadata["spotify.processing_error"] = String(describing: processingError)
            if case .unknown(let description) = processingError {
                metadata["spotify.processing_error_detail"] = description
            }
        }

        return metadata
    }

    private func phaseName(_ phase: StreamingConnectionPhase) -> String {
        switch phase {
        case .initial: return "initial"
        case .connecting: return "connecting"
        case .processing: return "processing"
        case .success: return "success"
        case .genreResults: return "genre_results"
        case .error: return "error"
        }
    }

    private func statusName(_ status: SpotifyServiceSyncStatus) -> String {
        switch status {
        case .idle: return "idle"
        case .syncing: return "syncing"
        case .processing: return "processing"
        case .completed: return "completed"
        case .failed(let error):
            return "failed:\(String(describing: type(of: error)))"
        }
    }

}


// MARK: - Preview

#if DEBUG
struct SpotifyConnectionContent_Previews: PreviewProvider {
    static var previews: some View {
        GradientBackgroundView {
            VStack {
                Spacer()
                
                SpotifyConnectionContent(
                    service: StreamingService.spotify,
                    onComplete: { _ in
                        print("Flow completed")
                    },
                    onCancel: {
                        print("Flow cancelled")
                    },
                    onCloseButtonVisibilityChanged: { visible in
                        print("Close button visibility: \(visible)")
                    },
                    onProcessingStateChanged: { processing in
                        print("Processing state: \(processing)")
                    },
                    onSuccessStateChanged: { success in
                        print("Success state: \(success)")
                    },
                    onErrorStateChanged: { error in
                        print("Error state: \(error)")
                    }
                )
                .background(
                    RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
                        .fill(ColorSystem.Text.primary.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.large)
                                .stroke(ColorSystem.Text.primary.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: ColorSystem.Utility.shadow.opacity(0.3), radius: 30, x: 0, y: 15)
                
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
