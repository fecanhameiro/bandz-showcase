import SwiftUI

/// Supported visual styles for Bandz toasts
public struct BandzToastStyle {
    public let icon: String
    public let iconColor: Color
    public let backgroundColor: Color
    public let borderColor: Color

    public init(icon: String,
                iconColor: Color,
                backgroundColor: Color,
                borderColor: Color) {
        self.icon = icon
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
    }

    public static let success = BandzToastStyle(
        icon: "checkmark.circle",
        iconColor: ColorSystem.Feedback.success,
        backgroundColor: ColorSystem.Feedback.successBackground,
        borderColor: ColorSystem.Feedback.successBorder
    )

    public static let error = BandzToastStyle(
        icon: "xmark.octagon",
        iconColor: ColorSystem.Feedback.error,
        backgroundColor: ColorSystem.Feedback.errorBackground,
        borderColor: ColorSystem.Feedback.errorBorder
    )
}

/// Kinds of toast supported by the system
public enum ToastKind {
    case success
    case error
    case custom(style: BandzToastStyle)

    var style: BandzToastStyle {
        switch self {
        case .success:
            return .success
        case .error:
            return .error
        case .custom(let style):
            return style
        }
    }
}

/// Data model representing a toast message
public struct BandzToast: Identifiable, Equatable {
    public let id: UUID
    public let kind: ToastKind
    public let titleKey: String
    public let titleArgs: [CVarArg]
    public let messageKey: String?
    public let messageArgs: [CVarArg]
    public let ttl: TimeInterval?
    public let haptics: UINotificationFeedbackGenerator.FeedbackType?
    public let accessibilityOverride: String?
    public let icon: String?
    public let onTap: (() -> Void)?

    public init(id: UUID = UUID(),
                kind: ToastKind,
                titleKey: String,
                titleArgs: [CVarArg] = [],
                messageKey: String? = nil,
                messageArgs: [CVarArg] = [],
                ttl: TimeInterval? = nil,
                haptics: UINotificationFeedbackGenerator.FeedbackType? = nil,
                accessibilityOverride: String? = nil,
                icon: String? = nil,
                onTap: (() -> Void)? = nil) {
        self.id = id
        self.kind = kind
        self.titleKey = titleKey
        self.titleArgs = titleArgs
        self.messageKey = messageKey
        self.messageArgs = messageArgs
        self.ttl = ttl
        self.haptics = haptics
        self.accessibilityOverride = accessibilityOverride
        self.icon = icon
        self.onTap = onTap
    }
}

extension BandzToast {
    public static func == (lhs: BandzToast, rhs: BandzToast) -> Bool {
        lhs.id == rhs.id
    }
}
