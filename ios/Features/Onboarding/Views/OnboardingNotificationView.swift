//
//  NotificationOnboardingView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 15/06/25.
//

import SwiftUI
import Lottie
import UserNotifications

struct OnboardingNotificationView: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    @SwiftUI.Environment(UserDataManager.self) private var userDataManager: UserDataManager?
    @Inject private var logger: Logger
    private let loggingContext = "Onboarding.Notification"
    
    // MARK: - Properties
    private var currentStep: Int { OnboardingStep.notificationPermission.stepNumber }
    let onContinue: () -> Void
    let onBack: () -> Void
    
    // Animation states — individual triggers for cascaded entrance
    @State private var hasAnimated = false
    @State private var animateHeader = false
    @State private var animateTitle = false
    @State private var animateLottie = false
    @State private var animateButtons = false
    
    // MARK: - Lottie Animation Names
    private var notificationAnimation: String {
        return colorScheme == .dark ? "onboarding_notification_dark" : "onboarding_notification_light"
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
                    notificationLottieContainer
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
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: SpacingSystem.Size.xs) {
            Text("onboarding.notification.title".localized)
                .h3(alignment: .center)
                .bandzForegroundStyle(.primary)
                .lineLimit(nil)

            Text("onboarding.notification.subtitle".localized)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .lineLimit(nil)
        }
    }
    
    // MARK: - Lottie Container
    private var notificationLottieContainer: some View {
        OnboardingLottieContainer(fileName: notificationAnimation)
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
        BandzGlassButton(
            "onboarding.notification.enable_notifications".localized,
            style: .darkGlass
        ) {
            AnalyticsManager.shared.logCustomEvent("onboarding_notification_continue_tapped")
            requestNotificationPermission()
        }
    }
    
    // MARK: - Skip Button
    private var skipButton: some View {
        Button(action: {
            HapticManager.shared.play(.impact(.light))
            AnalyticsManager.shared.logCustomEvent("onboarding_notification_skip_tapped")
            saveNotificationPreference(enabled: false)
            onContinue()
        }) {
            Text("common.skip_for_now".localized)
                .bodyEmphasized(alignment: .center)
                .bandzForegroundStyle(.accent)
                .multilineTextAlignment(.center)
                .underline()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Notification Permission Request
    private func requestNotificationPermission() {
        HapticManager.shared.play(.impact(.medium))
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])

                AnalyticsManager.shared.logCustomEvent("onboarding_notification_permission_result", parameters: ["granted": granted])

                if granted {
                    HapticManager.shared.play(.notification(.success))
                    // Register for remote notifications to obtain APNs token
                    UIApplication.shared.registerForRemoteNotifications()
                    logger.info("Notification permission granted", metadata: notificationMetadata(extra: ["granted": true]), context: loggingContext)
                } else {
                    logNotificationWarning("Notification permission denied by user")
                }

                saveNotificationPreference(enabled: granted)
            } catch {
                AnalyticsManager.shared.logCustomEvent("onboarding_notification_error", parameters: ["error": error.localizedDescription])
                logNotificationError("Notification permission request failed", error: error)
                saveNotificationPreference(enabled: false)
            }

            onContinue()
        }
    }
    
    // MARK: - Save Notification Preference
    private func saveNotificationPreference(enabled: Bool) {
        // Update notification permission through UserDataManager
        userDataManager?.updateNotificationPermission(enabled: enabled)

        // Note: Data is kept in memory only - persistence happens at onboarding completion

        AnalyticsManager.shared.logCustomEvent("onboarding_notification_preference_saved", parameters: [
            "notifications_enabled": enabled
        ])

        logger.debug("Notification preference saved: \(enabled)", metadata: notificationMetadata(extra: ["enabled": enabled]), context: loggingContext)
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

private extension OnboardingNotificationView {
    func notificationMetadata(extra: [String: Any] = [:]) -> [String: Any] {
        var metadata: [String: Any] = [
            "feature": "Onboarding",
            "screen": "OnboardingNotificationView",
            "tags": ["Onboarding", "Notifications"]
        ]
        for (key, value) in extra {
            metadata[key] = value
        }
        return metadata
    }

    func logNotificationWarning(_ message: String, metadata: [String: Any] = [:]) {
        let combined = notificationMetadata(extra: metadata)
        logger.warning(message, metadata: combined, context: loggingContext)
    }

    func logNotificationError(_ message: String, error: Error, metadata: [String: Any] = [:]) {
        var combined = notificationMetadata(extra: metadata)
        combined["error.context"] = message
        combined["error.type"] = String(describing: type(of: error))
        logger.log(error: error, metadata: combined, context: loggingContext)
    }
}

// MARK: - Preview
#Preview("Notification Onboarding - Light") {
    OnboardingNotificationView(
        onContinue: {
            print("onContinue tapped")
        },
        onBack: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Notification Onboarding - Dark") {
    OnboardingNotificationView(
        onContinue: {
            print("onContinue tapped")
        },
        onBack: {}
    )
    .preferredColorScheme(.dark)
}
