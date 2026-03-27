import SwiftUI

// MARK: - Onboarding Step Header Component
struct OnboardingStepHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let stepIcons: [String]
    let accentColor: Color
    let onStepTapped: ((Int) -> Void)?
    
    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateIcons = false
    @State private var entranceAnimated = false
    
    // Default initializer with bandz app icons
    init(
        currentStep: Int,
        totalSteps: Int = 6,
        accentColor: Color = ColorSystem.Brand.primary,
        onStepTapped: ((Int) -> Void)? = nil
    ) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.accentColor = accentColor
        self.onStepTapped = onStepTapped
        self.stepIcons = [
            "link.circle",      // Connect services explanation
            "music.note.list",  // Streaming options
            "heart.circle",     // Music genre
            "location.circle",  // Location permission
            "star.circle",      // Favorite places
            "bell.circle"       // Notifications
        ]
    }
    
    // Custom initializer for different apps
    init(
        currentStep: Int,
        totalSteps: Int,
        stepIcons: [String],
        accentColor: Color = ColorSystem.Brand.primary,
        onStepTapped: ((Int) -> Void)? = nil
    ) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.stepIcons = stepIcons
        self.accentColor = accentColor
        self.onStepTapped = onStepTapped
    }
    
    var body: some View {
        VStack(spacing: SpacingSystem.Size.md) {
            HStack {
                ForEach(1...totalSteps, id: \.self) { step in
                    VStack(spacing: SpacingSystem.Size.xs) {
                        // Themed icons for each step
                        getIconForStep(step)
                            .font(.system(
                                size: LayoutSystem.ElementSize.smallIcon,
                                weight: Typography.FontWeight.medium
                            ))
                            .foregroundStyle(
                                step <= currentStep ?
                                accentColor :
                                    ColorSystem.Text.tertiary
                            )
                            .scaleEffect(step == currentStep ? 1.2 : 1.0)
                            .opacity(step <= currentStep ? 1.0 : 0.4)
                            .animation(
                                OnboardingAnimation.selection,
                                value: currentStep
                            )
                        
                        // Step indicator dot
                        Circle()
                            .fill(
                                step <= currentStep ?
                                accentColor :
                                    ColorSystem.State.disabled
                            )
                            .frame(
                                width: SpacingSystem.Size.xxs + SpacingSystem.Size.xxxs,
                                height: SpacingSystem.Size.xxs + SpacingSystem.Size.xxxs
                            )
                            .scaleEffect(step == currentStep ? 1.5 : 1.0)
                            .animation(
                                OnboardingAnimation.selection,
                                value: currentStep
                            )
                    }
                    .contentShape(Rectangle()) // Makes entire area tappable
                    .onTapGesture {
                        // Allow tapping on previous steps and current step
                        if step <= currentStep {
                            // Generate haptic feedback for navigation
                            HapticManager.shared.selection()
                            onStepTapped?(step)
                        }
                    }
                    .scaleEffect(step < currentStep ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
                    // Cascade entrance animation
                    .scaleEffect(entranceAnimated ? 1.0 : 0.01)
                    .opacity(entranceAnimated ? 1.0 : 0.0)
                    .animation(
                        OnboardingAnimation.entrance.delay(Double(step - 1) * 0.08),
                        value: entranceAnimated
                    )
                    
                    if step < totalSteps {
                        // Connection line with animated fill
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(ColorSystem.State.disabled)
                                .frame(height: SpacingSystem.Size.xxxs)

                            // Animated fill overlay
                            GeometryReader { geo in
                                Capsule()
                                    .fill(accentColor)
                                    .frame(
                                        width: step < currentStep ? geo.size.width : 0,
                                        height: SpacingSystem.Size.xxxs
                                    )
                                    .animation(.easeInOut(duration: 0.5), value: currentStep)
                            }
                            .frame(height: SpacingSystem.Size.xxxs)
                        }
                        // Cascade entrance — lines appear between their adjacent icons
                        .scaleEffect(x: entranceAnimated ? 1.0 : 0.0, y: 1.0, anchor: .leading)
                        .opacity(entranceAnimated ? 1.0 : 0.0)
                        .animation(
                            OnboardingAnimation.entrance.delay(Double(step - 1) * 0.08 + 0.04),
                            value: entranceAnimated
                        )
                    }
                }
            }
            .padding(.horizontal, LayoutSystem.AdaptiveSize.horizontalPadding())
        }
        .frame(height: LayoutSystem.ElementSize.navigationBar + SpacingSystem.Size.lg)
        .background(ColorSystem.Utility.clear) // Explicit clear background
        .onAppear {
            animateIcons = true
            // Entrance cascade — each icon/line scales in with stagger.
            // With reduceMotion, set instantly via transaction to skip animation.
            if reduceMotion {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    entranceAnimated = true
                }
            } else {
                entranceAnimated = true
            }
        }
        .onChange(of: currentStep) { _, _ in
            // Reset animation when step changes
            animateIcons = false
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                animateIcons = true
            }
        }
    }
    
    @ViewBuilder
    private func getIconForStep(_ step: Int) -> some View {
        let iconIndex = step - 1

        if iconIndex >= stepIcons.count {
            Image(systemName: "circle")
        } else {
            let iconName = stepIcons[iconIndex]
            let isActive = step == currentStep && animateIcons
            let speed = iconName == "music.note.list" || iconName == "bell.circle" ? 0.4 : 0.3

            if #available(iOS 18.0, *) {
                Image(systemName: iconName)
                    .symbolEffect(.bounce, options: .speed(speed), isActive: isActive)
            } else {
                Image(systemName: iconName)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isActive)
            }
        }
    }
}

// MARK: - Usage Examples with Bandz Design System
struct OnboardingStepHeaderPreviews: View {
    @State private var currentStep = 3
    
    var body: some View {
        ScrollView {
            VStack(spacing: SpacingSystem.Size.xl) {
                VStack(alignment: .leading, spacing: SpacingSystem.Size.md) {
                    Text("Bandz App - With Navigation")
                        .textStyle(Typography.TextStyle.h3)
                        .bandzForegroundStyle(.primary)
                    
                    Text("Try tapping on previous steps!")
                        .textStyle(Typography.TextStyle.caption)
                        .bandzForegroundStyle(.secondary)
                    
                    OnboardingStepHeader(
                        currentStep: currentStep,
                        onStepTapped: { step in
                            print("Tapped step: \(step)")
                            withAnimation(.spring()) {
                                currentStep = step
                            }
                        }
                    )
                    .bandzBackgroundStyle(.primaryGradient)
                    .bandzCornerRadius("medium")
                    .elevation(ElevationSystem.Level.subtle)
                }
                
                VStack(alignment: .leading, spacing: SpacingSystem.Size.md) {
                    Text("Custom Usage - Different Icons")
                        .textStyle(Typography.TextStyle.h3)
                        .bandzForegroundStyle(.primary)
                    
                    OnboardingStepHeader(
                        currentStep: currentStep,
                        totalSteps: 4,
                        stepIcons: [
                            "person.circle",
                            "envelope.circle",
                            "checkmark.circle",
                            "star.fill"
                        ],
                        accentColor: ColorSystem.Secondary.base,
                        onStepTapped: { step in
                            withAnimation(.spring()) {
                                currentStep = step
                            }
                        }
                    )
                    .padding()
                    .bandzCornerRadius("medium")
                    .elevation(ElevationSystem.Level.subtle)
                }
                
                // Test controls using Bandz design system
                HStack {
                    Button("Previous") {
                        if currentStep > 1 {
                            withAnimation(.spring()) {
                                currentStep -= 1
                            }
                        }
                    }
                    .textStyle(Typography.TextStyle.buttonMedium)
                    .bandzForegroundStyle(currentStep <= 1 ? .disabled : .primary)
                    .disabled(currentStep <= 1)
                    
                    Spacer()
                    
                    Text("Step \(currentStep)")
                        .textStyle(Typography.TextStyle.subtitle)
                        .bandzForegroundStyle(.primary)
                    
                    Spacer()
                    
                    Button("Next") {
                        if currentStep < 6 {
                            withAnimation(.spring()) {
                                currentStep += 1
                            }
                        }
                    }
                    .textStyle(Typography.TextStyle.buttonMedium)
                    .bandzForegroundStyle(currentStep >= 6 ? .disabled : .primary)
                    .disabled(currentStep >= 6)
                }
                .standardPadding()
            }
            .standardPadding()
        }
    }
}

#Preview {
    OnboardingStepHeaderPreviews()
        .withThemeController()
}
