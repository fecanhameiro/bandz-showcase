//
//  LocationOnboardingView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 15/06/25.
//

import SwiftUI
import Lottie
import CoreLocation

struct OnboardingLocationView: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var locationManager = LocationManager()
    @SwiftUI.Environment(UserDataManager.self) private var userDataManager: UserDataManager?
    @Inject private var logger: Logger
    private let loggingContext = "OnboardingLocation"
    
    // MARK: - Properties
    private var currentStep: Int { OnboardingStep.locationPermission.stepNumber }
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void
    
    // MARK: - State
    @State private var permissionHandled = false
    @State private var detectedCityName: String?

    // Animation states — individual triggers for cascaded entrance
    @State private var hasAnimated = false
    @State private var animateHeader = false
    @State private var animateTitle = false
    @State private var animateLottie = false
    @State private var animateButtons = false
    
    // MARK: - Lottie Animation Names
    private var locationAnimation: String {
        return colorScheme == .dark ? "onboarding_location_dark" : "onboarding_location_light"
    }
    
    // MARK: - Body
    var body: some View {
        GradientBackgroundView(type: .onboarding) {
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

                // Main Content
                VStack(spacing: SpacingSystem.Size.none) {
                    // Title and Subtitle Section — slides down
                    titleSection
                        .padding(.top, SpacingSystem.Size.xs)
                        .padding(.horizontal, SpacingSystem.Size.lg)
                        .offset(y: animateTitle ? 0 : -20)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .animation(OnboardingAnimation.staggerDelay(index: 1), value: animateTitle)

                    Spacer(minLength: SpacingSystem.Size.md)
                        .frame(maxHeight: SpacingSystem.Size.xxxl)

                    // Lottie Animation Container — scales in
                    locationLottieContainer
                        .frame(maxHeight: 300)
                        .scaleEffect(animateLottie ? 1.0 : 0.85)
                        .opacity(animateLottie ? 1.0 : 0.0)
                        .animation(OnboardingAnimation.staggerDelay(index: 2), value: animateLottie)

                    Spacer()
                }
                .overlay(alignment: .bottom) {
                    // Buttons Section — slides up from below
                    buttonsContent
                        .onboardingBottomPill()
                        .offset(y: animateButtons ? 0 : 30)
                        .opacity(animateButtons ? 1.0 : 0.0)
                        .animation(OnboardingAnimation.staggerDelay(index: 3), value: animateButtons)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startElementsAnimation()
            permissionHandled = false
            locationManager.checkPermissionStatus()
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            handlePermissionStatusChange(newStatus)
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: SpacingSystem.Size.xs) {
            Text("onboarding.location.title".localized)
                .h3(alignment: .center)
                .bandzForegroundStyle(.primary)
                .lineLimit(nil)

            Text("onboarding.location.subtitle".localized)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .lineLimit(nil)
        }
    }
    
    // MARK: - Lottie Container
    private var locationLottieContainer: some View {
        OnboardingLottieContainer(fileName: locationAnimation)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - Buttons Content
    private var buttonsContent: some View {
        VStack(spacing: SpacingSystem.Size.md) {
            // Main Continue Button
            continueButton

            // Skip Button
            skipButton
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        VStack(spacing: SpacingSystem.Size.sm) {
            BandzGlassButton(
                "onboarding.location.use_current_location".localized,
                isLoading: locationManager.isRequestingPermission && detectedCityName == nil,
                style: .darkGlass
            ) {
                requestLocationPermission()
            }

            // Feedback de cidade detectada
            if let city = detectedCityName {
                HStack(spacing: SpacingSystem.Size.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ColorSystem.Feedback.success)
                    Text(city)
                        .bodyEmphasized()
                        .bandzForegroundStyle(.primary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
    }
    
    // MARK: - Skip Button
    private var skipButton: some View {
        Button(action: {
            skipLocationPermission()
        }) {
            Text("common.skip_for_now".localized)
                .bodyEmphasized(alignment: .center)
                .bandzForegroundStyle(.accent)
                .multilineTextAlignment(.center)
                .underline()
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(locationManager.isRequestingPermission)
        .opacity(locationManager.isRequestingPermission ? 0.6 : 1.0)
    }
    
    // MARK: - Location Permission Logic
    
    private func requestLocationPermission() {
        HapticManager.shared.play(.impact(.medium))
        AnalyticsManager.shared.logCustomEvent("onboarding_location_continue_tapped")

        locationManager.requestWhenInUseAuthorization { [self] granted in
            if granted {
                Task { @MainActor in
                    HapticManager.shared.play(.notification(.success))
                    do {
                        let userLocation = try await locationManager.getCurrentLocationWithGeocoding()
                        saveLocationPreference(enabled: true, userLocation: userLocation)

                        // Mostrar cidade detectada brevemente antes de avançar
                        let cityDisplay = [userLocation.city, userLocation.state]
                            .compactMap { $0 }
                            .filter { !$0.isEmpty }
                            .joined(separator: ", ")
                        if !cityDisplay.isEmpty {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                detectedCityName = cityDisplay
                            }
                            try? await Task.sleep(for: .milliseconds(1200))
                        }
                    } catch {
                        logLocationWarning("Failed to fetch user location after permission granted", error: error)
                        saveLocationPreference(enabled: true, userLocation: nil)

                        AnalyticsManager.shared.logCustomEvent("onboarding_location_geocoding_error", parameters: [
                            "error": error.localizedDescription
                        ])
                    }

                    if !permissionHandled {
                        permissionHandled = true
                        onContinue()
                    }
                }
            } else {
                Task { @MainActor in
                    saveLocationPreference(enabled: false, userLocation: nil)
                    if !permissionHandled {
                        permissionHandled = true
                        onContinue()
                    }
                }
                logLocationWarning("Location permission denied by user")
            }
        }
    }
    
    private func skipLocationPermission() {
        HapticManager.shared.play(.impact(.light))
        AnalyticsManager.shared.logCustomEvent("onboarding_location_skip_tapped")
        Task { @MainActor in
            saveLocationPreference(enabled: false, userLocation: nil)
            onSkip()
        }
    }
    
    private func handlePermissionStatusChange(_ status: CLAuthorizationStatus) {
        // Don't auto-handle while user is actively responding to the permission prompt
        guard !locationManager.isRequestingPermission else { return }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if !permissionHandled {
                Task { @MainActor in
                    saveLocationPreference(enabled: true, userLocation: nil)
                    permissionHandled = true
                    onContinue()
                }
            }
        case .denied, .restricted:
            if !permissionHandled {
                Task { @MainActor in
                    saveLocationPreference(enabled: false, userLocation: nil)
                    permissionHandled = true
                    onContinue()
                }
                logLocationWarning("Location permission denied or restricted outside onboarding prompt", metadata: ["status": "denied_or_restricted"])
            }
        case .notDetermined:
            break
        @unknown default:
            if !permissionHandled {
                Task { @MainActor in
                    saveLocationPreference(enabled: false, userLocation: nil)
                    permissionHandled = true
                    onContinue()
                }
                logLocationWarning("Received unknown location authorization status", metadata: ["status": String(describing: status)])
            }
        }
    }
    
    private func saveLocationPreference(enabled: Bool, userLocation: UserLocation?) {
        // Update location permission through UserDataManager
        userDataManager?.updateLocationPermission(granted: enabled)

        // Update user location if available
        if let userLocation = userLocation {
            userDataManager?.updateUserLocation(userLocation)
        }

        // Note: Data is kept in memory only - persistence happens at onboarding completion

        var analyticsParams: [String: Any] = ["location_enabled": enabled]
        if let location = userLocation {
            analyticsParams["city"] = location.city ?? "unknown"
            analyticsParams["state"] = location.state ?? "unknown"
            analyticsParams["country"] = location.country ?? "unknown"
            analyticsParams["has_geocoding"] = true
        } else {
            analyticsParams["has_geocoding"] = false
        }

        AnalyticsManager.shared.logCustomEvent("onboarding_location_preference_saved", parameters: analyticsParams)

        if let location = userLocation {
            logger.debug("Location saved: \(location.displayName)", context: loggingContext)
        } else {
            logger.debug("Location permission saved: \(enabled)", context: loggingContext)
        }
    }
    
    // MARK: - Animation Functions
    private func startElementsAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        Task { @MainActor in
            await OnboardingAnimation.cascade(reduceMotion: reduceMotion, steps: [
                { animateHeader = true },
                { animateTitle = true },
                { animateLottie = true },
                { animateButtons = true }
            ])
        }
    }
}

// MARK: - Location Lottie Container
private extension OnboardingLocationView {
    func locationMetadata(extra: [String: Any] = [:]) -> [String: Any] {
        var metadata: [String: Any] = [
            "feature": "Onboarding",
            "screen": "OnboardingLocationView",
            "tags": ["Onboarding", "Location"],
            "authorization_status": locationManager.authorizationStatus.rawValue
        ]
        for (key, value) in extra {
            metadata[key] = value
        }
        return metadata
    }

    func logLocationWarning(_ message: String, error: Error? = nil, metadata: [String: Any] = [:]) {
        var combined = locationMetadata(extra: metadata)
        if let error {
            combined["error"] = error.localizedDescription
            combined["error.type"] = String(describing: type(of: error))
        }
        logger.warning(message, metadata: combined, context: loggingContext)
    }

}

/// Container Lottie unificado para telas de onboarding (Location, Notification, etc.)
/// Usa aspectRatio em vez de scale hardcoded por device para resiliência em novos devices.
struct OnboardingLottieContainer: View {
    let fileName: String

    var body: some View {
        LottieView(animation: .named(fileName))
            .looping()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }
}

// MARK: - Preview
#Preview("Location Onboarding - Light") {
    OnboardingLocationView(
        onContinue: {
            print("Continue tapped")
        },
        onBack: {}, onSkip: {
            print("Skip tapped")
        }
    )
    .preferredColorScheme(.light)
}

#Preview("Location Onboarding - Dark") {
    OnboardingLocationView(
        onContinue: {
            print("Continue tapped")
        },
        onBack: {}, onSkip: {
            print("Skip tapped")
        }
    )
    .preferredColorScheme(.dark)
    
}
