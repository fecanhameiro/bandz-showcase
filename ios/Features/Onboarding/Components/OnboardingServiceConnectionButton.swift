//
//  OnboardingStreamingConnectionButton.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 15/06/25.
//

import SwiftUI

struct ServiceConnectionButton: View {
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    let service: StreamingService
    let isAnimating: Bool
    let animationDelay: Double
    let onTap: () -> Void
    var buttonHeight: CGFloat = SpacingSystem.Size.xxxl
    
    // MARK: - Loading State Properties
    var isLoading: Bool = false
    
    @State private var buttonAnimating = false
    
    // Button color — delegates to centralized StreamingService model
    private var buttonColor: Color {
        service.adaptiveBrandColor(for: colorScheme)
    }
    
    
    // Button text - uses service.name or custom localized strings
    private var buttonText: String {
        switch service.id {
            case "spotify":
                return service.context == .login ? "login.continue_with_spotify".localized : "onboarding.connect_spotify".localized
            case "youtube_music":
                return service.context == .login ? "login.continue_with_youtube_music".localized : "onboarding.connect_youtube_music".localized
            case "apple_music":
                return service.context == .login ? "login.continue_with_apple_music".localized : "onboarding.connect_apple_music".localized
            case "deezer":
                return service.context == .login ? "login.continue_with_deezer".localized : "onboarding.connect_deezer".localized
            case "google":
                return "login.continue_with_google".localized
            case "facebook":
                return "login.continue_with_facebook".localized
            case "apple":
                return "login.continue_with_apple".localized
            case "phone":
                return "login.continue_with_phone".localized
            default:
                return service.name
        }
    }
    
    // Check if it's phone button (different layout)
    private var isSystemImage: Bool {
        return service.id == "phone" || service.id == "anonymous" || service.id == "apple"
    }

    // Text/icon color — delegates to centralized StreamingService model
    private var contentColor: Color {
        service.contentColor(for: colorScheme)
    }
    
    var body: some View {
        Button(action: isLoading ? {} : onTap) {
            ZStack {
                // Button Text - always centered
                Text(buttonText)
                    .bodyEmphasized()
                    .foregroundStyle(contentColor)
                
                // Service Icon - always positioned on the left
                HStack {
                    if isSystemImage {
                        Image(systemName: service.iconName)
                            .font(.title3)
                            .foregroundStyle(contentColor)
                            .frame(width: LayoutSystem.ElementSize.smallIcon, height: LayoutSystem.ElementSize.smallIcon)
                    } else {
                        Image(service.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                width: LayoutSystem.ElementSize.smallIcon,
                                height: LayoutSystem.ElementSize.smallIcon
                            )
                            .foregroundStyle(contentColor)
                    }
                    
                    Spacer()
                }
                
                // Loading indicator - positioned on the right
                if isLoading {
                    HStack {
                        Spacer()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                            .tint(contentColor)
                    }
                }
            }
            .padding(.horizontal, SpacingSystem.Size.lg)
            .padding(.vertical, SpacingSystem.Size.lg)
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
                    .fill(buttonColor)
                    .stroke((service.id == "phone" || service.id == "anonymous") ? ColorSystem.Text.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .overlay(
                // Shimmer loading effect
                Group {
                    if isLoading {
                        shimmerLoadingOverlay
                    }
                }
            )
            .elevation(.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .opacity(buttonAnimating ? 1.0 : 0.0)
        .animation(
            .easeInOut(duration: 0.4)
            .delay(animationDelay),
            value: buttonAnimating
        )
        .onAppear {
            if isAnimating {
                buttonAnimating = true
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                buttonAnimating = true
            }
        }
    }
    
    // MARK: - Shimmer Loading Overlay
    
    private var shimmerLoadingOverlay: some View {
        ZStack {
            // Custom shimmer effect for service buttons
            ServiceButtonShimmerEffect(
                color: buttonColor,
                isAnimating: isLoading
            )
            .clipShape(
                RoundedRectangle(cornerRadius: SpacingSystem.CornerRadius.extraLarge)
            )
        }
    }
}

// MARK: - ServiceButtonShimmerEffect

/// Custom shimmer effect designed specifically for ServiceConnectionButton
/// Adapts to service-specific colors and maintains button aesthetics
struct ServiceButtonShimmerEffect: View {
    
    @State private var animationOffset: CGFloat = -1
    @State private var pulseOpacity: Double = 0.3
    
    private let color: Color
    private let isAnimating: Bool
    private let animationDuration: Double = 1.5
    
    init(color: Color, isAnimating: Bool = true) {
        self.color = color
        self.isAnimating = isAnimating
    }
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    // Main shimmer wave
                    shimmerWave(geometry: geometry)
                )
                .overlay(
                    // Subtle pulse overlay
                    pulseOverlay
                )
        }
        .onAppear {
            if isAnimating {
                startShimmerAnimation()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startShimmerAnimation()
            } else {
                stopShimmerAnimation()
            }
        }
    }
    
    private func shimmerWave(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        ColorSystem.Text.primary.opacity(0),
                        ColorSystem.Text.primary.opacity(0.3),
                        ColorSystem.Text.primary.opacity(0.2),
                        ColorSystem.Text.primary.opacity(0.3),
                        ColorSystem.Text.primary.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: geometry.size.width * 0.7)
            .offset(x: animationOffset * geometry.size.width * 1.8)
            .blendMode(.overlay)
    }
    
    private var pulseOverlay: some View {
        Rectangle()
            .fill(ColorSystem.Text.primary.opacity(pulseOpacity))
            .blendMode(.overlay)
    }
    
    private func startShimmerAnimation() {
        // Wave animation
        withAnimation(
            .linear(duration: animationDuration)
            .repeatForever(autoreverses: false)
        ) {
            animationOffset = 1.0
        }
        
        // Pulse animation
        withAnimation(
            .easeInOut(duration: animationDuration * 0.6)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.1
        }
    }
    
    private func stopShimmerAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            animationOffset = -1.0
            pulseOpacity = 0.3
        }
    }
}
