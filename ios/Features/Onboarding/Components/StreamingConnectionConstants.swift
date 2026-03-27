//
//  StreamingConnectionConstants.swift
//  Bandz
//
//  Created by Claude Code on 09/10/25.
//  Centralized constants for streaming service connection flows
//

import Foundation
import CoreGraphics

/// Centralized constants used across all streaming service connection flows
/// (Spotify, Apple Music, YouTube Music, Deezer, etc.)
enum StreamingConnectionConstants {

    // MARK: - Timing

    /// Animation and transition timings
    enum Timing {
        /// Delay between success and genre results view
        static let successToResultsDelay: TimeInterval = 1.0

        /// Delay before navigating after dialog close (matches spring animation response: 0.6 + buffer)
        static let dialogCloseDelay: TimeInterval = 0.7

        /// Spring animation response duration
        static let springResponse: Double = 0.8

        /// Spring animation damping fraction
        static let springDamping: Double = 0.9

        /// Delay before checkmark bounce animation
        static let checkmarkBounceDelay: TimeInterval = 0.2
    }

    // MARK: - Progress

    /// Progress bar values for different states
    enum Progress {
        /// Connecting/authorizing state
        static let connecting: Double = 0.25

        /// Collecting data state
        static let collecting: Double = 0.4

        /// Processing data state
        static let processing: Double = 0.75

        /// Completed state
        static let completed: Double = 1.0
    }

    // MARK: - Retry

    /// Retry and timeout configuration
    enum Retry {
        /// Maximum retry attempts for connection flow
        static let maxAttempts: Int = 3

        /// Maximum retry attempts for Firebase listener
        static let listenerMaxAttempts: Int = 2

        /// Timeout for Cloud Function processing
        static let timeoutSeconds: TimeInterval = 30
    }

    // MARK: - Animation

    /// Animation configuration values
    enum Animation {
        /// Heights for waveform bars animation
        static let waveformHeights: [CGFloat] = [8, 20, 32, 16, 24]

        /// Duration of waveform animation cycle
        static let waveformDuration: Double = 0.6

        /// Delay between each waveform bar animation
        static let waveformDelay: Double = 0.1

        /// Duration of pulse/scale animation
        static let pulseDuration: Double = 1.2

        /// Duration of shimmer effect
        static let shimmerDuration: Double = 1.5

        /// Checkmark bounce scale
        static let checkmarkBounceScale: CGFloat = 1.1

        /// Music icon pulse scale range
        static let musicIconScaleMin: CGFloat = 0.9
        static let musicIconScaleMax: CGFloat = 1.1

        /// Music icon opacity range
        static let musicIconOpacityMin: Double = 0.7
        static let musicIconOpacityMax: Double = 1.0
    }

    // MARK: - UI

    /// UI sizing constants
    enum UI {
        /// Large icon size (initial, error views)
        static let largeIconSize: CGFloat = 56

        /// Medium icon size (connecting, processing views)
        static let mediumIconSize: CGFloat = 40

        /// Success icon size
        static let successIconSize: CGFloat = 56

        /// Error icon size
        static let errorIconSize: CGFloat = 56

        /// Progress bar width
        static let progressBarWidth: CGFloat = 180

        /// Progress bar height
        static let progressBarHeight: CGFloat = 6

        /// Progress bar corner radius
        static let progressBarCornerRadius: CGFloat = 3
    }
}
