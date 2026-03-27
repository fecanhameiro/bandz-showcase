//
//  StreamingSelectionOnboardingView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 14/06/25.
//

import SwiftUI
import Lottie
// MARK: - Streaming Selection Onboarding View
struct OnboardingStreamingSelectionView: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Inject private var logger: Logger
    private let loggingContext = "Onboarding.Streaming.Selection"

    // Animation states — individual triggers for cascaded entrance
    @State private var hasAnimated = false
    @State private var animateHeader = false
    @State private var animateTitle = false
    @State private var animateGrid = false
    @State private var animateButton = false
    
    @State private var selectedService: StreamingService?
    @State private var connectedService: StreamingService?
    @State private var showConnectionDialog = false
    @State private var shouldShowCloseButton = true // Controls close button visibility
    @State private var isProcessing = false // Track processing state for shimmer
    @State private var isSuccess = false // Track success state for green dialog
    @State private var isError = false // Track error state for red dialog tint
    @State private var pendingDisconnectService: StreamingService?
    @State private var showDisconnectAlert = false
    @Namespace private var spotifyDialogNamespace
    
    let onContinue: () -> Void
    let onBack: () -> Void
    let onStreamingConnected: (StreamingService, _ hasDiscoveredGenres: Bool) -> Void
    let onStreamingDisconnected: (StreamingService) -> Void
    let onContinueWithoutConnect: () -> Void
    
    private var currentStep: Int { OnboardingStep.streamingSelection.stepNumber }
    
    // Streaming services for connection — sourced from central model
    private var streamingServices: [StreamingService] { StreamingService.allStreamingServices }
    
    init(
        initiallyConnectedService: StreamingService? = nil,
        onContinue: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onStreamingConnected: @escaping (StreamingService, _ hasDiscoveredGenres: Bool) -> Void,
        onStreamingDisconnected: @escaping (StreamingService) -> Void,
        onContinueWithoutConnect: @escaping () -> Void
    ) {
        self.onContinue = onContinue
        self.onBack = onBack
        self.onStreamingConnected = onStreamingConnected
        self.onStreamingDisconnected = onStreamingDisconnected
        self.onContinueWithoutConnect = onContinueWithoutConnect
        _selectedService = State(initialValue: initiallyConnectedService)
        _connectedService = State(initialValue: initiallyConnectedService)
    }
    
    var body: some View {
        mainContent
        .onAppear {
            log(.info, "Streaming selection view appeared")
            startElementsAnimation()
            syncSelectionWithConnectedService()
        }
        .onChange(of: connectedService) { _, _ in
            syncSelectionWithConnectedService()
            if let connectedService {
                log(.info, "Streaming service connected", metadata: serviceMetadata(connectedService))
            } else {
                log(.info, "Streaming service disconnected")
            }
        }
        .onChange(of: showConnectionDialog) { _, isPresented in
            if !isPresented {
                scheduleSelectionReset()
                log(.debug, "Connection dialog dismissed")
            } else {
                log(.debug, "Connection dialog presented")
            }
        }
    }
    
    private func syncSelectionWithConnectedService() {
        if let connectedService {
            selectedService = connectedService
            log(.debug, "Selection synchronized with connected service", metadata: serviceMetadata(connectedService))
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        GradientBackgroundView(type: .onboarding) {
            streamingSelectionView
        }
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()
        .overlay(alignment: .bottom) {
            bottomButtonOverlay
        }
        .overlay(connectionDialogOverlay)
        .alert(
            "onboarding.streaming_disconnect_title".localized,
            isPresented: $showDisconnectAlert,
            presenting: pendingDisconnectService
        ) { service in
            Button("onboarding.streaming_disconnect_confirm".localized, role: .destructive) {
                disconnectService(service)
            }
            Button("onboarding.streaming_disconnect_cancel".localized, role: .cancel) {
                pendingDisconnectService = nil
            }
        } message: { service in
            Text(String(format: "onboarding.streaming_disconnect_message".localized, service.name))
        }
    }

    private var bottomButtonOverlay: some View {
        BandzGlassButton(
            bottomButtonTitle.localized,
            style: .darkGlass
        ) {
            handleBottomButtonTap()
        }
        .onboardingBottomPill()
        .offset(y: animateButton ? 0 : 30)
        .opacity(animateButton ? 1.0 : 0.0)
        .animation(OnboardingAnimation.staggerDelay(index: 3), value: animateButton)
    }

    @ViewBuilder
    private var connectionDialogOverlay: some View {
        if let service = selectedService {
            BandzDialog(
                isPresented: $showConnectionDialog,
                namespace: spotifyDialogNamespace,
                state: isSuccess ? .success : (isError ? .error : .normal),
                isLoading: isProcessing,
                dismissOnBackdropTap: shouldShowCloseButton,
                showCloseButton: shouldShowCloseButton,
                contentPadding: EdgeInsets(),
                maxWidth: nil
            ) {
                connectionDialogContent(for: service)
            }
        }
    }

    // MARK: - Connection Dialog Content

    @ViewBuilder
    private func connectionDialogContent(for service: StreamingService) -> some View {
        switch service.id {
        case "spotify":
            SpotifyConnectionContent(
                service: service,
                onComplete: { hasGenres in
                    connectedService = service
                    dismissConnectionDialog()
                    onStreamingConnected(service, hasGenres)
                    onContinue()
                },
                onCancel: {
                    dismissConnectionDialog()
                },
                onCloseButtonVisibilityChanged: { visible in
                    shouldShowCloseButton = visible
                },
                onProcessingStateChanged: { processing in
                    isProcessing = processing
                },
                onSuccessStateChanged: { success in
                    isSuccess = success
                },
                onErrorStateChanged: { error in
                    isError = error
                }
            )
        case "apple_music":
            AppleMusicConnectionContent(
                service: service,
                onComplete: { hasGenres in
                    connectedService = service
                    dismissConnectionDialog()
                    onStreamingConnected(service, hasGenres)
                    onContinue()
                },
                onCancel: {
                    dismissConnectionDialog()
                },
                onCloseButtonVisibilityChanged: { visible in
                    shouldShowCloseButton = visible
                },
                onProcessingStateChanged: { processing in
                    isProcessing = processing
                },
                onSuccessStateChanged: { success in
                    isSuccess = success
                },
                onErrorStateChanged: { error in
                    isError = error
                }
            )
        default:
            StreamingComingSoonContent(serviceName: service.name) {
                dismissConnectionDialog()
            }
            .onAppear {
                shouldShowCloseButton = true
                isProcessing = false
                isSuccess = false
                isError = false
            }
        }
    }

    // MARK: - Streaming Selection View
    private var streamingSelectionView: some View {
        VStack(spacing: SpacingSystem.Size.none) {
            // Step Header — slides down from above
            OnboardingStepHeader(
                currentStep: currentStep,
                accentColor: ColorSystem.Brand.primary,
                onStepTapped: { _ in
                    onBack() // Sempre volta 1 step
                }
            )
            .offset(y: animateHeader ? 0 : -15)
            .opacity(animateHeader ? 1.0 : 0.0)
            .animation(OnboardingAnimation.staggerDelay(index: 0), value: animateHeader)

            // Title Section — slides down
            titleSection
                .padding(.top, SpacingSystem.Size.xs)
                .padding(.horizontal, SpacingSystem.Size.lg)
                .offset(y: animateTitle ? 0 : -20)
                .opacity(animateTitle ? 1.0 : 0.0)
                .animation(OnboardingAnimation.staggerDelay(index: 1), value: animateTitle)

            // Streaming Service Buttons — scales in
            streamingServicesSection
                .padding(.top, SpacingSystem.Size.lg)
                .scaleEffect(animateGrid ? 1.0 : 0.92)
                .opacity(animateGrid ? 1.0 : 0.0)
                .animation(OnboardingAnimation.staggerDelay(index: 2), value: animateGrid)

            Spacer()
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: SpacingSystem.Size.xs) {
            Text("onboarding.streaming_selection_title".localized)
                .h3(alignment: .center)
                .bandzForegroundStyle(.primary)
                .lineLimit(nil)
            
            Text("onboarding.streaming_selection_subtitle".localized)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .lineLimit(nil)
        }
    }
    
    // MARK: - Streaming Services Section
    private var streamingServicesSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: SpacingSystem.Size.md),
            GridItem(.flexible(), spacing: SpacingSystem.Size.md)
        ], spacing: SpacingSystem.Size.md) {
            ForEach(Array(streamingServices.enumerated()), id: \.element.id) { index, service in
                UnifiedTileView(
                    title: service.name,
                    subtitle: nil,
                    imageName: service.iconName,
                    tileType: .streaming(service.brandColor),
                    actionMode: .button,
                    isSelected: isServiceSelected(service),
                    isAnimating: false, // Disabled since whole section animates together
                    animationDelay: 0,
                    showDistance: false,
                    distanceText: nil
                ) {
                    handleServiceConnection(service)
                }
                .overlay(alignment: .topTrailing) {
                    if connectedService?.id == service.id {
                        ConnectedBadge()
                            .padding(.top, SpacingSystem.Size.xs)
                            .padding(.trailing, SpacingSystem.Size.xs)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(.horizontal, SpacingSystem.Size.lg)
    }
    
    
    
    // MARK: - Animation Functions
    private func startElementsAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        Task { @MainActor in
            await OnboardingAnimation.cascade(reduceMotion: reduceMotion, steps: [
                { animateHeader = true },
                { animateTitle = true },
                { animateGrid = true },
                { animateButton = true }
            ])
        }
    }
    
    
    private func handleServiceConnection(_ service: StreamingService) {
        log(.info, "Streaming service tile tapped", metadata: serviceMetadata(service))
        if connectedService?.id == service.id {
            pendingDisconnectService = service
            showDisconnectAlert = true
            log(.warning, "Prompting disconnect confirmation", metadata: serviceMetadata(service))
            return
        }
        // Animação da borda com feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedService = service
        }
        log(.info, "Streaming service selection pending", metadata: serviceMetadata(service))

        // Haptic feedback
        HapticManager.shared.impact(style: .medium)

        // Mostrar dialog após pequeno delay para ver a animação - COM ANIMAÇÃO
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showConnectionDialog = true
            }
        }
        
        AnalyticsManager.shared.logCustomEvent("onboarding_streaming_service_selected", parameters: [
            "service": service.id
        ])
    }
    
    // MARK: - Dialog Management
    
    /// Dismisses connection dialog and resets selection
    private func dismissConnectionDialog() {
        log(.debug, "Dismissing connection dialog")
        isProcessing = false
        isSuccess = false
        isError = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showConnectionDialog = false
        }
        
        scheduleSelectionReset()
    }

    private func scheduleSelectionReset() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if let connectedService {
                    selectedService = connectedService
                    log(.debug, "Selection reset to connected service", metadata: serviceMetadata(connectedService))
                } else {
                    selectedService = nil
                    log(.debug, "Selection cleared")
                }
            }
        }
    }

    private func isServiceSelected(_ service: StreamingService) -> Bool {
        if connectedService?.id == service.id { return true }
        return selectedService?.id == service.id
    }
    
    private var bottomButtonTitle: String {
        connectedService != nil ? "onboarding.continue" : "common.skip_for_now"
    }
    
    private func handleBottomButtonTap() {
        HapticManager.shared.play(.impact(.medium))
        if connectedService != nil {
            log(.info, "Continuing onboarding with connected service")
            onContinue()
        } else {
            log(.warning, "Continuing onboarding without streaming connection")
            handleContinueWithoutConnect()
        }
    }

    private func handleContinueWithoutConnect() {
        let previouslyConnectedService = connectedService
        connectedService = nil
        selectedService = nil
        if let service = previouslyConnectedService {
            onStreamingDisconnected(service)
            log(.warning, "User chose to continue without streaming", metadata: serviceMetadata(service))
        } else {
            log(.warning, "User skipped streaming connection")
        }
        onContinueWithoutConnect()
    }

    private func disconnectService(_ service: StreamingService) {
        guard connectedService?.id == service.id else { return }
        log(.warning, "Disconnecting streaming service", metadata: serviceMetadata(service))
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            connectedService = nil
            selectedService = nil
        }
        pendingDisconnectService = nil
        showDisconnectAlert = false
        onStreamingDisconnected(service)
    }
    
    // MARK: - Logging

    private func log(_ level: LogLevel, _ message: String, metadata: [String: Any] = [:]) {
        let combined = baseMetadata(extra: metadata)
        logger.log(level: level, message: message, metadata: combined, context: loggingContext)
    }

    private func baseMetadata(extra: [String: Any] = [:]) -> [String: Any] {
        var metadata: [String: Any] = [
            "feature": "Onboarding",
            "screen": "StreamingSelection",
            "tags": ["Streaming", "Onboarding"]
        ]

        if let connectedId = connectedService?.id {
            metadata["connected_service"] = connectedId
        }

        if let selectedId = selectedService?.id {
            metadata["selected_service"] = selectedId
        }

        for (key, value) in extra {
            metadata[key] = value
        }

        return metadata
    }

    private func serviceMetadata(_ service: StreamingService) -> [String: Any] {
        [
            "service": service.id,
            "service_name": service.name
        ]
    }
    
}

private struct ConnectedBadge: View {
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: LayoutSystem.ElementSize.smallIcon, weight: .semibold))
            .foregroundStyle(ColorSystem.Feedback.success)
            .background(
                Circle()
                    .fill(ColorSystem.Icon.backgroundPrimary)
                    .frame(width: LayoutSystem.ElementSize.smallIcon * 0.7, height: LayoutSystem.ElementSize.smallIcon * 0.7)
            )
            .shadow(color: ColorSystem.Feedback.success.opacity(0.3), radius: 2, x: 0, y: 1)
            .accessibilityLabel("onboarding.streaming_connected_status".localized)
    }
}


// MARK: - Preview
#Preview {
    OnboardingStreamingSelectionView(
        initiallyConnectedService: StreamingService.spotify,
        onContinue: {},
        onBack: {},
        onStreamingConnected: { _, _ in },
        onStreamingDisconnected: { _ in },
        onContinueWithoutConnect: {}
    )
}

// MARK: - Coming Soon Content

private struct StreamingComingSoonContent: View {
    let serviceName: String
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: SpacingSystem.Size.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: LayoutSystem.ElementSize.stateIcon))
                .foregroundStyle(ColorSystem.Brand.primary)

            Text(String(format: "onboarding.streaming_coming_soon_title".localized, serviceName))
                .h5(alignment: .center)
                .bandzForegroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("onboarding.streaming_coming_soon_subtitle".localized)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .multilineTextAlignment(.center)

            BandzGlassButton("common.ok".localized, style: .darkGlass) {
                onClose()
            }
        }
        .padding(.vertical, SpacingSystem.Size.lg)
        .padding(.horizontal, SpacingSystem.Size.md)
    }
}
