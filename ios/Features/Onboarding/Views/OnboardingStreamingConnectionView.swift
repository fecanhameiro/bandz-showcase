//
//  StreamingConnectionOnboardingView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 14/06/25.
//

import SwiftUI
import Lottie

// MARK: - Streaming Connection Onboarding View
struct OnboardingStreamingConnectionView: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Animation states — individual triggers for cascaded entrance
    @State private var hasAnimated = false
    @State private var animateHeader = false
    @State private var animateTitle = false
    @State private var animateLottie = false
    @State private var animateButton = false
    
    let onContinue: () -> Void
    let onBack: () -> Void
    let onNavigateToWelcome: () -> Void
    
    private var currentStep: Int { OnboardingStep.streamingConnectionsInfo.stepNumber }
    
    // Streaming services — sourced from central model
    private var streamingServices: [StreamingService] { StreamingService.allStreamingServices }
    
    // MARK: - Lottie Animation Names
    private var surfAnimation: String {
        return colorScheme == .dark ? "onboarding_connect_surf_dark" : "onboarding_connect_surf_light"
    }
    
    private var wavesAnimation: String {
        return colorScheme == .dark ? "onboarding_connect_waves_dark" : "onboarding_connect_waves_light"
    }
    
    
    var body: some View {
        GradientBackgroundView(type: .onboarding, isAnimated: true) {
            VStack(spacing: SpacingSystem.Size.none) {
                // Step Header — slides down from above
                OnboardingStepHeader(
                    currentStep: currentStep,
                    accentColor: ColorSystem.Brand.primary,
                    onStepTapped: { step in
                        if step == currentStep {
                            onNavigateToWelcome()
                        } else {
                            onBack()
                        }
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

                // Streaming Services
                streamingServicesSection
                    .padding(.top, SpacingSystem.Size.md)

                // Lottie animation area — scales in
                Spacer(minLength: 0)

                lottieAnimationSection
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .scaleEffect(animateLottie ? 1.0 : 0.9)
                    .opacity(animateLottie ? 1.0 : 0.0)
                    .animation(OnboardingAnimation.staggerDelay(index: 2), value: animateLottie)
            }
            .overlay(alignment: .bottom) {
                // Continue Button
                BandzGlassButton(
                    "onboarding.continue".localized,
                    style: .darkGlass
                ) {
                    HapticManager.shared.play(.impact(.medium))
                    AnalyticsManager.shared.logCustomEvent("onboarding_streaming_continue_tapped")
                    onContinue()
                }
                .onboardingBottomPill()
                .offset(y: animateButton ? 0 : 30)
                .opacity(animateButton ? 1.0 : 0.0)
                .animation(OnboardingAnimation.staggerDelay(index: 3), value: animateButton)
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
            Text("onboarding.streaming_title".localized)
                .h3(alignment: .center)
                .bandzForegroundStyle(.primary)
                .lineLimit(nil)
            
            Text("onboarding.streaming_subtitle".localized)
                .bodyRegular(alignment: .center)
                .bandzForegroundStyle(.secondary)
                .lineLimit(nil)
        }
    }
    
    // MARK: - Streaming Services Section
    private var streamingServicesSection: some View {
        // Streaming service logos positioned over transparent Lottie background
        HStack(spacing: SpacingSystem.Size.lg) {
            ForEach(Array(streamingServices.enumerated()), id: \.element.id) { index, service in
                StreamingServiceLogo(
                    service: service,
                    animationDelay: Double(index) * 0.1
                )
                .frame(maxWidth: .infinity) // Equal distribution
            }
        }
        .padding(.horizontal, SpacingSystem.Size.lg)
        .background(
            StreamingWindLottieContainer(fileName: wavesAnimation)
        )
    }
    
    // MARK: - Lottie Animation Section (Bottom Area Background)
    private var lottieAnimationSection: some View {
        StreamingSurfLottieContainer(fileName: surfAnimation)
    }
    
    
    // MARK: - Helper Functions
    private func startElementsAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        Task { @MainActor in
            await OnboardingAnimation.cascade(reduceMotion: reduceMotion, steps: [
                { animateHeader = true },
                { animateTitle = true },
                { animateLottie = true },
                { animateButton = true }
            ])
        }
    }
    
}

// MARK: - Streaming Service Logo (Display Only)
struct StreamingServiceLogo: View {
    let service: StreamingService
    let animationDelay: Double
    
    @State private var logoAnimating = false
    
    // Map service IDs to actual asset names in StreamLogo folder
    private var logoImageName: String {
        switch service.id {
            case "spotify":
                return "spotify_logo"
            case "youtube_music":
                return "youtube_logo_stream"
            case "deezer":
                return "deezer_logo"
            case "apple_music":
                return "apple_music_logo"
            default:
                return "spotify_logo" // fallback
        }
    }
    
    var body: some View {
        Image(logoImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                width: LayoutSystem.ElementSize.largeIcon,
                height: LayoutSystem.ElementSize.largeIcon
            )
            .scaleEffect(logoAnimating ? 1.0 : 0.8)
            .rotation3DEffect(
                .degrees(logoAnimating ? 0 : 15),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(logoAnimating ? 1.0 : 0.0)
            .animation(
                OnboardingAnimation.entrance.delay(animationDelay),
                value: logoAnimating
            )
            .onAppear {
                logoAnimating = true
            }
    }
}

// MARK: - Streaming Wind Lottie Container (for waves behind services)
struct StreamingWindLottieContainer: View {
    let fileName: String
    
    var body: some View {
        LottieView(animation: .named(fileName))
            .looping()
            .scaleEffect(x: 1.4, y: 1.4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Streaming Surf Lottie Container (Bottom Area Background)
struct StreamingSurfLottieContainer: View {
    let fileName: String

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width

            let baseScale: CGFloat = switch screenWidth {
                case ...375: 1.3  // iPhone SE, mini (375pt)
                case ...393: 1.5  // iPhone 16/16 Pro (393pt)
                case ...430: 1.7  // iPhone 16 Pro Max (430pt)
                default: 2.0      // iPad and larger
            }

            LottieView(animation: .named(fileName))
                .looping()
                .scaleEffect(baseScale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingStreamingConnectionView(
        onContinue: {},
        onBack: {},
        onNavigateToWelcome: {}
    )
}

