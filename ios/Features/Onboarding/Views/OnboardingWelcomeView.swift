//
//  OnboardingWelcomeView.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 14/06/25.
//

import SwiftUI
import Lottie

// MARK: - Main Onboarding View
struct OnboardingWelcomeView: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    @State private var isUserInteracting = false
    @State private var autoScrollTask: Task<Void, Never>?
    @State private var resumeTask: Task<Void, Never>?

    // Animation states
    @State private var hasAnimated = false
    @State private var animateHeader = false
    @State private var animateCarousel = false
    @State private var animateIndicators = false
    @State private var animateButtons = false
    
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    private var carouselItems: [CarouselItem] {
        [
            CarouselItem(
                lottieFileName: "onboarding_user",
                title: "onboarding.carousel_item_1_title".localized,
                subtitle: "onboarding.carousel_item_1_subtitle".localized,
                scale: 2.0
            ),
            CarouselItem(
                lottieFileName: colorScheme == .dark ? "onboarding_concert_dark" : "onboarding_concert",
                title: "onboarding.carousel_item_2_title".localized,
                subtitle: "onboarding.carousel_item_2_subtitle".localized,
                scale: 1.35
            ),
            CarouselItem(
                // TODO: Create onboarding_places_light.json — currently using dark variant for both themes
                lottieFileName: "onboarding_places_dark",
                title: "onboarding.carousel_item_3_title".localized,
                subtitle: "onboarding.carousel_item_3_subtitle".localized,
                scale: 1.4
            )
        ]
    }
    
    var body: some View {
        GradientBackgroundView(type: .onboarding, isAnimated: true) {
            VStack(spacing: SpacingSystem.Size.none) {
                // Header with logo
                headerSection
                    .padding(.horizontal, SpacingSystem.Size.lg)
                    .offset(y: animateHeader ? 0 : -50)
                    .opacity(animateHeader ? 1.0 : 0.0)
                    .animation(OnboardingAnimation.staggerDelay(index: 0, base: 0.1), value: animateHeader)
                
                Spacer(minLength: SpacingSystem.Size.lg)
                    .frame(maxHeight: SpacingSystem.Size.max)

                // Main carousel content (full width)
                carouselSection
                    .scaleEffect(animateCarousel ? 1.0 : 0.8)
                    .opacity(animateCarousel ? 1.0 : 0.0)
                    .animation(OnboardingAnimation.staggerDelay(index: 1, base: 0.2), value: animateCarousel)
                
                // Page indicators
                pageIndicators
                    .padding(.horizontal, SpacingSystem.Size.lg)
                    .opacity(animateIndicators ? 1.0 : 0.0)
                    .animation(OnboardingAnimation.staggerDelay(index: 2, base: 0.3), value: animateIndicators)
                
                Spacer()

                // Bottom section with button
                bottomContent
                    .onboardingBottomPill()
                    .offset(y: animateButtons ? 0 : 50)
                    .opacity(animateButtons ? 1.0 : 0.0)
                    .animation(OnboardingAnimation.staggerDelay(index: 3, base: 0.4), value: animateButtons)
            }
            .padding(.top, SpacingSystem.Size.xxxl)
        }
        .onAppear {
            startWelcomeAnimation()
            startAutoScroll()
        }
        .onDisappear {
            autoScrollTask?.cancel()
            autoScrollTask = nil
            resumeTask?.cancel()
            resumeTask = nil
        }
        .navigationBarBackButtonHidden(true) // Welcome screen não tem back button

    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: SpacingSystem.Size.xs) {
            Text("onboarding.welcome_to".localized)
                .textStyle(Typography.TextStyle.display)
                .bandzForegroundStyle(.primary)

            brandGlowText
        }
    }

    private var brandGlowText: some View {
        Text("onboarding.app_name".localized)
            .displayXLargeFutura(alignment: .center)
            .bandzForegroundStyle(.primary)
            .tracking(1.2)
    }
    
    // MARK: - Carousel Section
    private var carouselSection: some View {
        GeometryReader { geometry in
            let illustrationHeight = geometry.size.height * 0.5
            let tabHeight = geometry.size.height

            VStack(spacing: SpacingSystem.Size.xl) {
                TabView(selection: $currentPage) {
                    ForEach(Array(carouselItems.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: SpacingSystem.Size.lg) {
                            LottieAnimationContainer(
                                fileName: item.lottieFileName,
                                scale: item.scale
                            )
                            .frame(height: illustrationHeight)

                            VStack(spacing: SpacingSystem.Size.md) {
                                Text(item.title)
                                    .h3(alignment: .center)
                                    .bandzForegroundStyle(.primary)
                                    .padding(.top, SpacingSystem.Size.md)

                                Text(item.subtitle)
                                    .bodyRegular(alignment: .center)
                                    .bandzForegroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                            .padding(.horizontal, SpacingSystem.Size.lg)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: tabHeight)
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                .onChange(of: currentPage) { _, _ in
                    if isUserInteracting {
                        HapticManager.shared.selection()
                        autoScrollTask?.cancel()
                        scheduleAutoScrollResume()
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            isUserInteracting = true
                            autoScrollTask?.cancel()
                        }
                        .onEnded { _ in
                            scheduleAutoScrollResume()
                        }
                )
            }
        }
    }
    
    // MARK: - Page Indicators
    private var pageIndicators: some View {
        PageIndicatorView(count: carouselItems.count, current: currentPage, variant: .onLight)
            .padding(.vertical, SpacingSystem.Size.md)
    }
    
    // MARK: - Bottom Content
    private var bottomContent: some View {
        VStack(spacing: SpacingSystem.Size.md) {
            BandzGlassButton("onboarding.start_button".localized, style: .darkGlass) {
                HapticManager.shared.impact(style: .medium)
                AnalyticsManager.shared.logCustomEvent("onboarding_start_button_tapped")
                onContinue()
            }

            ExistingUserView {
                AnalyticsManager.shared.logCustomEvent("onboarding_login_button_tapped")
                onSkip()
            }
        }
    }
    
    // MARK: - Animation Functions
    private func startWelcomeAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        Task { @MainActor in
            await OnboardingAnimation.cascade(reduceMotion: reduceMotion, steps: [
                { animateHeader = true },
                { animateCarousel = true },
                { animateIndicators = true },
                { animateButtons = true }
            ])
        }
    }

    // MARK: - Auto Scroll Functions
    private func startAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = Task { @MainActor in
            // Delay to let entrance animation complete
            try? await Task.sleep(for: .milliseconds(2000))
            guard !Task.isCancelled else { return }

            // Auto-scroll loop using structured concurrency
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5.0))
                guard !Task.isCancelled, !isUserInteracting else { continue }
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentPage = (currentPage + 1) % carouselItems.count
                }
            }
        }
    }

    private func scheduleAutoScrollResume() {
        resumeTask?.cancel()
        resumeTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(8.0))
            guard !Task.isCancelled else { return }
            isUserInteracting = false
            startAutoScroll()
        }
    }
}

// MARK: - Lottie Animation Container
struct LottieAnimationContainer: View {
    let fileName: String
    let scale: CGFloat

    var body: some View {
        LottieView(animation: .named(fileName))
            .looping()
            .animationSpeed(0.6)
            .scaleEffect(scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Models
struct CarouselItem: Identifiable {
    var id: String { lottieFileName }
    let lottieFileName: String
    let title: String
    let subtitle: String
    let scale: CGFloat
}

// MARK: - Preview
#Preview {
    OnboardingWelcomeView(
        onContinue: {},
        onSkip: {}
    )
}
