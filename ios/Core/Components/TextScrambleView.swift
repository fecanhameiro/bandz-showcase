//
//  TextScrambleView.swift
//  Bandz
//
//  Departure-board style text scramble animation.
//  Each character "decodes" from left to right through random characters
//  before settling on the final value.
//

import SwiftUI

struct TextScrambleView: View {

    // MARK: - Public Properties

    let text: String
    var frameInterval: TimeInterval = 0.033  // ~30fps
    var resolveInterval: TimeInterval = 0.045 // Time between each char resolving
    var initialDelay: TimeInterval = 0.15     // Delay before scramble starts

    // MARK: - State

    @State private var displayedText: String = ""
    @State private var scrambleTask: Task<Void, Never>?

    @SwiftUI.Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private static let scrambleCharacters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789#$%&@!?")

    // MARK: - Body

    var body: some View {
        Text(displayedText)
            .onAppear {
                displayedText = text
            }
            .onChange(of: text) { _, newValue in
                if reduceMotion {
                    displayedText = newValue
                } else {
                    startScramble(to: newValue)
                }
            }
            .onDisappear {
                scrambleTask?.cancel()
            }
    }

    // MARK: - Scramble Animation

    private func startScramble(to target: String) {
        scrambleTask?.cancel()

        let targetChars = Array(target)
        let totalChars = targetChars.count
        let framesPerResolve = max(1, Int(resolveInterval / frameInterval))
        let totalFrames = framesPerResolve * totalChars + framesPerResolve

        scrambleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(initialDelay * 1000)))
            guard !Task.isCancelled else { return }

            var resolvedCount = 0

            for frame in 0..<totalFrames {
                guard !Task.isCancelled else { return }

                let newResolved = min(frame / framesPerResolve, totalChars)
                if newResolved > resolvedCount {
                    resolvedCount = newResolved
                }

                // Build scrambled string: resolved chars are final, rest are random
                // Spaces in the target are always preserved (never scrambled)
                var result = ""
                for i in 0..<totalChars {
                    let targetChar = targetChars[i]
                    if i < resolvedCount || targetChar == " " {
                        result.append(targetChar)
                    } else {
                        result.append(Self.scrambleCharacters.randomElement() ?? "?")
                    }
                }
                displayedText = result

                try? await Task.sleep(for: .milliseconds(Int(frameInterval * 1000)))
            }

            guard !Task.isCancelled else { return }

            displayedText = target
            HapticManager.shared.impact(style: .light)
        }
    }
}

// MARK: - Preview

#Preview("Text Scramble") {
    TextScramblePreview()
}

private struct TextScramblePreview: View {
    @State private var currentText = "Rock"
    private let options = ["Rock", "Jazz", "Hip Hop", "Electronic", "R&B"]
    @State private var index = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                HStack(spacing: 0) {
                    Text("Explore ")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    TextScrambleView(text: currentText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                Button("Next Genre") {
                    index = (index + 1) % options.count
                    currentText = options[index]
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
