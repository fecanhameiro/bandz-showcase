//
//  OnboardingFavoritePlacesSearchPrototype.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 06/08/25.
//

import SwiftUI
import UIKit

// MARK: - Prototype Root View

/// SwiftUI prototype para validar os três estados do rodapé (sem seleção, com seleção, busca ativa)
/// antes de avançar para a implementação completa no fluxo de onboarding.
struct OnboardingFavoritePlacesSearchPrototype: View {
    @State private var mode: BottomBarMode = .idleNoSelection
    @State private var hasSelection = false
    @State private var searchText = ""
    @Namespace private var bottomBarNamespace

    var body: some View {
        GradientBackgroundView(type: .onboarding, isAnimated: true) {
            VStack(alignment: .leading, spacing: SpacingSystem.Size.lg) {
                prototypeHeader
                prototypeControls
                Spacer()
            }
            .padding(.horizontal, SpacingSystem.Size.xl)
            .padding(.top, SpacingSystem.Size.xxl)
        }
        .overlay(alignment: .bottom) {
            FavoritePlacesBottomBarPrototype(
                mode: $mode,
                searchText: $searchText,
                hasSelection: hasSelection,
                namespace: bottomBarNamespace,
                onContinue: handleContinueTapped,
                onSearchActivated: handleSearchActivated,
                onSearchDismissed: handleSearchDismissed
            )
        }
        .onChange(of: hasSelection) { _, newValue in
            guard mode != .searchActive else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                mode = newValue ? .idleWithSelection : .idleNoSelection
            }
        }
        .onChange(of: searchText) {
            // Prototype logging only
        }
    }

    private var prototypeHeader: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.Size.xs) {
            Text("Favorite Places – Busca")
                .textStyle(Typography.TextStyle.h3, color: .white, alignment: .leading)
            Text("Interaja com os botões abaixo para validar animações e micro-interações do rodapé.")
                .textStyle(Typography.TextStyle.bodyRegular, color: Color.white.opacity(0.9), alignment: .leading)
        }
    }

    private var prototypeControls: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.Size.md) {
            Toggle(isOn: $hasSelection.animation(.spring(response: 0.45, dampingFraction: 0.85))) {
                Text("Simular seleção de lugares")
                    .textStyle(Typography.TextStyle.bodyEmphasized, color: .white, alignment: .leading)
            }
            .toggleStyle(SwitchToggleStyle(tint: ColorSystem.Primary.base))

            HStack(spacing: SpacingSystem.Size.md) {
                Button("Abrir busca") {
                    handleSearchActivated()
                }
                .buttonStyle(.bandzGlass)

                Button("Fechar busca") {
                    handleSearchDismissed()
                }
                .buttonStyle(.bandzGlass)
                .disabled(mode != .searchActive)
            }
        }
        .padding(.top, SpacingSystem.Size.md)
    }

    // MARK: - Prototype Actions

    private func handleContinueTapped() {
        #if DEBUG
        print("✅ Prototype continuar selecionado (hasSelection: \(hasSelection))")
        #endif
    }

    private func handleSearchActivated() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            mode = .searchActive
        }
    }

    private func handleSearchDismissed() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            searchText = ""
            mode = hasSelection ? .idleWithSelection : .idleNoSelection
        }
    }
}

// MARK: - Bottom Bar Mode

enum BottomBarMode {
    case idleNoSelection
    case idleWithSelection
    case searchActive
}

// MARK: - Prototype Bottom Bar

private struct FavoritePlacesBottomBarPrototype: View {
    @Binding var mode: BottomBarMode
    @Binding var searchText: String
    let hasSelection: Bool
    let namespace: Namespace.ID
    let onContinue: () -> Void
    let onSearchActivated: () -> Void
    let onSearchDismissed: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: .zero) {
                Spacer()

                switch mode {
                case .idleNoSelection:
                    idleNoSelection

                case .idleWithSelection:
                    overlayContainer(safeArea: geometry.safeAreaInsets.bottom) {
                        idleWithSelectionContent
                    }

                case .searchActive:
                    overlayContainer(safeArea: geometry.safeAreaInsets.bottom) {
                        searchActiveContent
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: mode) { _, newValue in
            withAnimation(.easeOut(duration: 0.1)) {
                isSearchFocused = (newValue == .searchActive)
            }
        }
    }

    // MARK: - States

    private var idleNoSelection: some View {
        VStack(spacing: .zero) {
            Spacer()

            HStack {
                Spacer()
                glassCircleButton(icon: "magnifyingglass", accessibilityLabel: "Buscar lugares")
            }
            .padding(.horizontal, SpacingSystem.Size.lg)
            .padding(.bottom, idleBottomPadding)
        }
    }

    private var idleWithSelectionContent: some View {
        HStack(spacing: SpacingSystem.Size.md) {
            BandzGlassButton("onboarding.continue".localized, style: .standard) {
                onContinue()
            }
            .matchedGeometryEffect(id: "primaryAction", in: namespace)

            glassCircleButton(icon: "magnifyingglass", accessibilityLabel: "Abrir busca de lugares")
            .matchedGeometryEffect(id: "secondaryAction", in: namespace)
        }
        .matchedGeometryEffect(id: "container", in: namespace)
    }

    private var searchActiveContent: some View {
        HStack(spacing: SpacingSystem.Size.sm) {
            searchField
                .matchedGeometryEffect(id: "primaryAction", in: namespace)

            glassCircleButton(
                icon: "xmark",
                accessibilityLabel: "Fechar busca",
                backgroundColor: ColorSystem.Primary.base
            )
            .matchedGeometryEffect(id: "secondaryAction", in: namespace)
        }
        .matchedGeometryEffect(id: "container", in: namespace)
    }

    // MARK: - Components

    private func overlayContainer<Content: View>(
        safeArea: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.clear, location: 0.0),
                .init(color: ColorSystem.Primary.base.opacity(0.15), location: 0.1),
                .init(color: ColorSystem.Primary.base.opacity(0.35), location: 0.25),
                .init(color: ColorSystem.Primary.base.opacity(0.6), location: 0.6),
                .init(color: ColorSystem.Primary.base.opacity(0.75), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: overlayHeight + safeArea)
        .overlay(alignment: .bottom) {
            HStack {
                content()
            }
            .padding(.horizontal, SpacingSystem.Size.lg)
            .padding(.bottom, overlayBottomPadding(safeArea))
        }
    }

    private var searchField: some View {
        BandzGlassTextField(
            "Buscar lugares",
            text: $searchText,
            style: .darkGlass,
            keyboardType: .default,
            onFocusChange: { isFocused in
                if !isFocused, searchText.isEmpty, mode == .searchActive {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                        onSearchDismissed()
                    }
                }
            }
        )
        .focused($isSearchFocused)
        .overlay(alignment: .trailing) {
            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                .padding(.trailing, SpacingSystem.Size.md)
                .buttonStyle(PressableCircleStyle())
                .accessibilityLabel("Limpar busca")
            }
        }
    }

    private func glassCircleButton(
        icon: String,
        accessibilityLabel: String,
        backgroundColor: Color = Color.white.opacity(0.18)
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                if icon == "magnifyingglass" {
                    onSearchActivated()
                } else {
                    onSearchDismissed()
                }
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: circleSize, height: circleSize)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 6)
                )
        }
        .buttonStyle(PressableCircleStyle())
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Layout helpers

    private var circleSize: CGFloat {
        SpacingSystem.Size.xxxl * 1.2
    }

    private var overlayHeight: CGFloat {
        SpacingSystem.Size.xxxl * 2.8
    }

    private var idleBottomPadding: CGFloat {
        SpacingSystem.Size.xl
    }

    private func overlayBottomPadding(_ safeArea: CGFloat) -> CGFloat {
        let basePadding = SpacingSystem.Size.lg
        return max(basePadding, safeArea + SpacingSystem.Size.md)
    }
}

// MARK: - Button Styles

private struct PressableCircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Favorite Places – Bottom Bar Prototype") {
    OnboardingFavoritePlacesSearchPrototype()
}
