//
//  OnboardingStateView.swift
//  Bandz
//
//  Reusable error/empty state view for onboarding screens.
//

import SwiftUI

struct OnboardingStateView: View {
    let icon: String
    let titleKey: String
    let messageKey: String
    let actionKey: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: SpacingSystem.Size.lg) {
            VStack(spacing: SpacingSystem.Size.md) {
                Image(systemName: icon)
                    .font(.system(size: LayoutSystem.ElementSize.stateIcon, weight: .light))
                    .foregroundStyle(ColorSystem.Brand.primarySoft)
                    .symbolEffect(.pulse.byLayer, options: .repeating)

                Text(titleKey.localized)
                    .h4()
                    .bandzForegroundStyle(.primary)

                Text(messageKey.localized)
                    .bodyRegular(alignment: .center)
                    .bandzForegroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, SpacingSystem.Size.lg)
            .padding(.top, SpacingSystem.Size.xxxl)

            BandzGlassButton(
                actionKey.localized,
                isLoading: isLoading,
                style: .darkGlass
            ) {
                action()
            }
            .disabled(isLoading)
            .padding(.horizontal, SpacingSystem.Size.lg)
        }
        .padding(.bottom, SpacingSystem.Size.lg)
    }
}
