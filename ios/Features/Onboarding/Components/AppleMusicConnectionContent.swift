//
//  AppleMusicConnectionContent.swift
//  Bandz
//
//  Created by OpenAI Codex on 09/08/24.
//  Updated by Claude Code on 09/10/25 - Parity with Spotify flow
//

import SwiftUI
import MusicKit
import Combine

// MARK: - Apple Music Connection Content

/// Complete Apple Music flow: connection → processing → genre results
/// Matches Spotify UX with Apple Music-specific branding
struct AppleMusicConnectionContent: View {
    let service: StreamingService
    let onComplete: (_ hasDiscoveredGenres: Bool) -> Void
    let onCancel: () -> Void
    let onCloseButtonVisibilityChanged: (Bool) -> Void
    let onProcessingStateChanged: (Bool) -> Void
    let onSuccessStateChanged: (Bool) -> Void
    let onErrorStateChanged: (Bool) -> Void

    private let integrationService: AppleMusicIntegrationServiceProtocol
    private let userDataManager: UserDataManager
    @Inject private var logger: Logger
    private let loggingContext = "Onboarding.Streaming.AppleMusic"

    @State private var syncStatus: AppleMusicSyncStatus = .idle
    @State private var processingResult: AppleMusicProcessingResult?
    @State private var currentPhase: StreamingConnectionPhase = .initial
    @State private var connectionTask: Task<Void, Never>?
    @State private var transitionTask: Task<Void, Never>?
    @State private var errorDescriptor: StreamingConnectionErrorDescriptor?
    @State private var statusCancellable: AnyCancellable?
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
        integrationService: AppleMusicIntegrationServiceProtocol? = nil,
        userDataManager: UserDataManager? = nil
    ) {
        self.service = service
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onCloseButtonVisibilityChanged = onCloseButtonVisibilityChanged
        self.onProcessingStateChanged = onProcessingStateChanged
        self.onSuccessStateChanged = onSuccessStateChanged
        self.onErrorStateChanged = onErrorStateChanged

        self.integrationService = integrationService ?? DIContainer.shared.resolveSafe(AppleMusicIntegrationServiceProtocol.self)
        self.userDataManager = userDataManager ?? DIContainer.shared.resolveSafe(UserDataManager.self)
    }

    var body: some View {
        StreamingConnectionLayout(
            service: service,
            phase: currentPhase,
            brandColor: adaptiveServiceColor,
            connectTitle: String(format: "applemusic.connect_to_service".localized, service.name),
            connectSubtitle: "applemusic.connection_description".localized,
            connectButtonTitle: "applemusic.connect_now".localized,
            isConnectLoading: isConnectionInProgress,
            onConnect: startConnectionFlow,
            connectingTitle: String(format: "applemusic.connecting".localized, service.name),
            connectingSubtitle: "applemusic.authorize_access".localized,
            processingTitle: "applemusic.analyzing_preferences".localized,
            processingSubtitle: "applemusic.discovering_genres".localized,
            processingStatusText: syncStatusText,
            processingProgress: syncProgress,
            canCancel: connectionTask != nil,
            onCancel: { cancelConnectionFlow() },
            successTitle: "applemusic.status_complete".localized,
            successSubtitle: "applemusic.discovering_genres".localized,
            errorTitle: "applemusic.connection_failed".localized,
            errorFallbackMessage: "applemusic.generic_error".localized,
            errorRetryTitle: "applemusic.retry".localized,
            errorDescriptor: errorDescriptor,
            onRetry: startConnectionFlow,
            onContinueAfterError: continueAfterErrorHandler,
            resultsContent: { AnyView(genreResultsView) }
        )
        .onAppear {
            log(.info, "Apple Music streaming dialog appeared")
            onCloseButtonVisibilityChanged(shouldShowCloseButton)
            startStatusListener()
        }
        .onDisappear {
            log(.debug, "Apple Music streaming dialog disappeared")
            statusCancellable?.cancel()
            statusCancellable = nil
            if currentPhase == .connecting || currentPhase == .processing {
                cancelConnectionFlow(resetPhase: false)
            }
        }
        .onChange(of: currentPhase) { previousPhase, newPhase in
            log(.debug, "Phase changed", metadata: [
                "previous_phase": phaseName(previousPhase),
                "new_phase": phaseName(newPhase)
            ])
            onCloseButtonVisibilityChanged(shouldShowCloseButton)
            onProcessingStateChanged(isInProcessingState)
            onSuccessStateChanged(isInSuccessState)
            onErrorStateChanged(newPhase == .error)

            if newPhase != .error {
                errorDescriptor = nil
            }

            if newPhase == .initial {
                processingResult = nil
            }
        }
    }

    private var continueAfterErrorHandler: (() -> Void)? {
        guard errorDescriptor?.allowsContinue == true else { return nil }
        return { continueAfterRecoverableError() }
    }

    private var hasGenreResults: Bool {
        guard let entries = processingResult?.processedGenreEntries else { return false }
        return !entries.isEmpty
    }

    private var genreResultsView: some View {
        VStack(spacing: SpacingSystem.Size.sm) {
            if hasGenreResults {
                // Fixed Header - Title
                VStack(spacing: SpacingSystem.Size.xs) {
                    Text("applemusic.discovered_genres_title".localized)
                        .h5(alignment: .center)
                        .bandzForegroundStyle(.primary)

                    Text("applemusic.based_on_library".localized)
                        .bodyRegular(alignment: .center)
                        .bandzForegroundStyle(.secondary)
                        .opacity(0.8)
                }
                .padding(.top, SpacingSystem.Size.sm)

                // Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: SpacingSystem.Size.lg) {
                        if let result = processingResult,
                           let processedEntries = result.processedGenreEntries {
                            MusicGenresPieChart(genres: processedEntries)
                                .padding(.top, SpacingSystem.Size.sm)

                            GenreResultsList(genres: processedEntries)
                                .padding(.horizontal, SpacingSystem.Size.xs)

                            ShareResultsButton(service: service, genres: processedEntries)
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
                "applemusic.continue".localized,
                style: .darkGlass,
                action: { [hasGenreResults] in
                    AnalyticsManager.shared.logCustomEvent("onboarding_genre_results_continue")

                    onCancel()

                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(StreamingConnectionConstants.Timing.dialogCloseDelay))
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

    // MARK: - Apple Music Integration Methods

    @MainActor
    private func startConnectionFlow() {
        guard connectionTask == nil else {
            log(.warning, "Ignoring Apple Music connection request because a task is already running")
            return
        }

        // Check retry limit
        guard retryCount < StreamingConnectionConstants.Retry.maxAttempts else {
            log(.error, "Maximum Apple Music retry attempts reached", metadata: [
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

        retryCount += 1
        errorDescriptor = nil
        processingResult = nil
        syncStatus = .authorizing
        log(.info, "Starting Apple Music connection flow", metadata: [
            "retry_attempt": retryCount
        ])
        connectionTask = Task { await runConnectionFlow() }
    }

    @MainActor
    private func runConnectionFlow() async {
        let startTime = Date()
        log(.info, "Running Apple Music connection flow", metadata: [
            "retry_attempt": retryCount
        ])

        AnalyticsManager.shared.logCustomEvent("applemusic_processing_started", parameters: [
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
        log(.debug, "Apple Music connection phase set to connecting")

        do {
            log(.debug, "Collecting data and awaiting Apple Music processing")
            let result = try await integrationService.collectAndAwaitProcessing()
            if Task.isCancelled {
                log(.warning, "Apple Music connection flow cancelled after data collection")
                return
            }

            let duration = Date().timeIntervalSince(startTime)

            processingResult = result
            syncStatus = .completed
            log(.debug, "Apple Music processing result available", metadata: [
                "processed_genre_entries": result.processedGenreEntries?.count ?? 0
            ])

            showSuccessThenResults()
            log(.info, "Apple Music processing completed", metadata: [
                "duration_ms": Int(duration * 1000),
                "genres_count": result.genres.count,
                "top_genre": result.genres.first?.name ?? "unknown",
                "dominant_genres": Array(result.dominantGenres.prefix(5)),
                "top_songs_count": result.topSongsCount,
                "recent_plays_count": result.recentPlaysCount,
                "upload_entries_count": result.uploadEntries.count
            ])

            AnalyticsManager.shared.logCustomEvent("applemusic_processing_completed", parameters: [
                "service": service.id,
                "genres_count": result.genres.count,
                "duration_seconds": Int(duration),
                "top_genre": result.genres.first?.name ?? "unknown",
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
            log(.warning, "Apple Music connection flow cancelled", metadata: [
                "elapsed_ms": Int(Date().timeIntervalSince(startTime) * 1000)
            ])
            AnalyticsManager.shared.logCustomEvent("applemusic_processing_cancelled", parameters: [
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
        log(.info, "Apple Music connection flow marked as success")

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
            log(.info, "Apple Music connection presenting genre results")
        }
    }

    @MainActor
    private func cancelConnectionFlow(resetPhase: Bool = true) {
        let hadActiveTask = connectionTask != nil
        log(.warning, "Cancelling Apple Music connection flow", metadata: [
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
        log(.debug, "Apple Music sync status reset to idle")
        if resetPhase {
            withAnimation(.spring(
                response: StreamingConnectionConstants.Timing.springResponse,
                dampingFraction: StreamingConnectionConstants.Timing.springDamping
            )) {
                currentPhase = .initial
            }
            log(.debug, "Apple Music connection flow reset to initial state")
        }
    }

    @MainActor
    private func handleConnectionError(_ error: Error, source: String = "run_flow") {
        transitionTask?.cancel()
        transitionTask = nil
        errorDescriptor = StreamingConnectionErrorDescriptor.makeForAppleMusic(error: error)
        let descriptorValue = errorDescriptor?.analyticsValue ?? "unknown"
        logError(error, message: "Apple Music connection flow failed", extra: [
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

        AnalyticsManager.shared.logCustomEvent("applemusic_processing_failed", parameters: [
            "service": service.id,
            "error": error.localizedDescription,
            "retry_count": retryCount
        ])
    }

    @MainActor
    private func updatePhaseForSyncStatus(_ status: AppleMusicSyncStatus) {
        switch status {
        case .idle, .completed:
            break
        case .authorizing:
            if currentPhase != .connecting {
                withAnimation(.spring(
                    response: StreamingConnectionConstants.Timing.springResponse,
                    dampingFraction: StreamingConnectionConstants.Timing.springDamping
                )) {
                    currentPhase = .connecting
                }
            }
        case .collecting, .processing, .uploading:
            if currentPhase != .processing {
                withAnimation(.spring(
                    response: StreamingConnectionConstants.Timing.springResponse,
                    dampingFraction: StreamingConnectionConstants.Timing.springDamping
                )) {
                    currentPhase = .processing
                }
            }
        case .failed(let error):
            handleConnectionError(error, source: "status_listener")
        }
    }

    @MainActor
    private func startStatusListener() {
        statusCancellable?.cancel()
        statusCancellable = integrationService.syncStatusPublisher
            .receive(on: RunLoop.main)
            .sink { status in
                syncStatus = status
                var statusMetadata: [String: Any] = [
                    "status": statusName(status)
                ]
                if case .failed(let error) = status {
                    statusMetadata["status_error"] = String(describing: error)
                    statusMetadata["status_error_localized"] = error.localizedDescription
                }
                log(.debug, "Received Apple Music sync status update", metadata: statusMetadata)
                updatePhaseForSyncStatus(status)
            }
    }

    @MainActor
    private func continueAfterRecoverableError() {
        log(.warning, "Continuing Apple Music onboarding after recoverable error", metadata: [
            "error_reason": errorDescriptor?.analyticsValue ?? "unknown"
        ])
        AnalyticsManager.shared.logCustomEvent("applemusic_processing_continued_after_error", parameters: [
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

        if let appleError = error as? AppleMusicServiceError {
            metadata["appleMusic.error"] = String(describing: appleError)
            switch appleError {
            case .authorizationFailed(let status):
                metadata["appleMusic.authorization_status"] = String(describing: status)
            case .authenticationFailed(let innerError):
                metadata["appleMusic.authentication_error"] = String(describing: innerError)
                metadata["appleMusic.authentication_error_localized"] = innerError.localizedDescription
            case .processingTimeout(let seconds):
                metadata["appleMusic.processing_timeout_seconds"] = seconds
            case .musicKitUnavailable, .processingIncomplete:
                break
            }
        }

        if let processingError = error as? AppleMusicProcessingError {
            metadata["appleMusic.processing_error"] = String(describing: processingError)
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

    private func statusName(_ status: AppleMusicSyncStatus) -> String {
        switch status {
        case .idle: return "idle"
        case .authorizing: return "authorizing"
        case .collecting: return "collecting"
        case .processing: return "processing"
        case .uploading: return "uploading"
        case .completed: return "completed"
        case .failed(let error):
            return "failed:\(String(describing: type(of: error)))"
        }
    }

    // MARK: - Computed Properties

    private var syncStatusText: String {
        switch syncStatus {
            case .idle:
                return "applemusic.status_preparing".localized
            case .authorizing:
                return "applemusic.authorize_access".localized
            case .collecting:
                return "applemusic.status_collecting".localized
            case .processing, .uploading:
                return "applemusic.status_processing".localized
            case .completed:
                return "applemusic.status_complete".localized
            case .failed:
                return "applemusic.status_failed".localized
        }
    }

    private var syncProgress: Double {
        switch syncStatus {
            case .idle:
                return 0.0
            case .authorizing:
                return StreamingConnectionConstants.Progress.connecting
            case .collecting:
                return StreamingConnectionConstants.Progress.collecting
            case .processing, .uploading:
                return StreamingConnectionConstants.Progress.processing
            case .completed:
                return StreamingConnectionConstants.Progress.completed
            case .failed:
                return 0.0
        }
    }

    private var adaptiveServiceColor: Color {
        service.adaptiveBrandColor(for: colorScheme)
    }

    // MARK: - Neutral Color System (State-Agnostic)

    @SwiftUI.Environment(\.colorScheme) private var colorScheme
}
