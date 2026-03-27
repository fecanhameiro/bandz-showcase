//
//  AnimationSystem.swift
//  Bandz
//
//  Centralized animation presets for consistent, premium animations across the app.
//

import SwiftUI

// MARK: - Onboarding Animation Presets
enum OnboardingAnimation {

    // MARK: - Entrance Springs

    /// Default entrance spring — balanced feel for most elements
    static let entrance = Animation.spring(response: 0.7, dampingFraction: 0.82)

    /// Fast entrance — buttons, small elements
    static let entranceFast = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Slow entrance — large illustrations, hero elements
    static let entranceSlow = Animation.spring(response: 0.85, dampingFraction: 0.82)

    // MARK: - Stagger Intervals

    /// Standard stagger between cascading elements (120ms)
    static let staggerInterval: Double = 0.12

    /// Slower stagger for more dramatic reveals (180ms)
    static let staggerIntervalSlow: Double = 0.18

    /// Sleep duration between cascade triggers (ms)
    static let cascadeSleepMs: Int = 150

    // MARK: - Interactive

    /// Press feedback spring
    static let press = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Selection toggle spring
    static let selection = Animation.spring(response: 0.4, dampingFraction: 0.75)

    // MARK: - Continuous

    /// Gentle icon pulse (scale oscillation)
    static let pulse = Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true)

    /// Slow breathing effect (backgrounds, large elements)
    static let breathing = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)

    // MARK: - Helpers

    /// Returns the entrance spring with a stagger delay based on element index.
    static func staggerDelay(index: Int, base: Double = 0.0) -> Animation {
        entrance.delay(base + Double(index) * staggerInterval)
    }

    /// Returns the slow entrance spring with a stagger delay.
    static func staggerDelaySlow(index: Int, base: Double = 0.0) -> Animation {
        entranceSlow.delay(base + Double(index) * staggerIntervalSlow)
    }

    // MARK: - Cascade Utility

    /// Cascades through animation triggers with the standard sleep interval between each step.
    /// If `reduceMotion` is true, all steps fire immediately without delays.
    @MainActor
    static func cascade(
        reduceMotion: Bool,
        steps: [() -> Void]
    ) async {
        guard !steps.isEmpty else { return }

        if reduceMotion {
            steps.forEach { $0() }
            return
        }

        for (index, step) in steps.enumerated() {
            step()
            if index < steps.count - 1 {
                try? await Task.sleep(for: .milliseconds(cascadeSleepMs))
                guard !Task.isCancelled else { return }
            }
        }
    }
}
