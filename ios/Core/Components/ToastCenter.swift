import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
public final class ToastCenter {
    private(set) var activeToasts: [BandzToast] = []

    @ObservationIgnored private var queue: [BandzToast] = []
    @ObservationIgnored private var dismissTasks: [UUID: Task<Void, Never>] = [:]

    public init() {}

    // MARK: - Public API
    public func show(_ toast: BandzToast) {
        if activeToasts.count >= 2 {
            queue.append(toast)
        } else {
            insertToast(toast)
        }
    }

    public func success(titleKey: String,
                        titleArgs: [CVarArg] = [],
                        messageKey: String? = nil,
                        messageArgs: [CVarArg] = [],
                        ttl: TimeInterval? = nil) {
        let toast = BandzToast(
            kind: .success,
            titleKey: titleKey,
            titleArgs: titleArgs,
            messageKey: messageKey,
            messageArgs: messageArgs,
            ttl: ttl ?? 3.2,
            haptics: .success
        )
        show(toast)
    }

    public func error(titleKey: String,
                      titleArgs: [CVarArg] = [],
                      messageKey: String? = nil,
                      messageArgs: [CVarArg] = [],
                      ttl: TimeInterval? = nil) {
        let toast = BandzToast(
            kind: .error,
            titleKey: titleKey,
            titleArgs: titleArgs,
            messageKey: messageKey,
            messageArgs: messageArgs,
            ttl: ttl ?? 4.5,
            haptics: .error
        )
        show(toast)
    }

    public func dismiss(id: UUID) {
        if let index = activeToasts.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.2)) {
                _ = activeToasts.remove(at: index)
            }
            dismissTasks[id]?.cancel()
            dismissTasks[id] = nil
            showNextIfNeeded()
        } else {
            queue.removeAll { $0.id == id }
        }
    }

    public func dismissAll() {
        withAnimation(.easeOut(duration: 0.18)) {
            activeToasts.removeAll()
        }
        queue.removeAll()
        dismissTasks.values.forEach { $0.cancel() }
        dismissTasks.removeAll()
    }

    // MARK: - Private Helpers
    private func insertToast(_ toast: BandzToast) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.2)) {
            activeToasts.insert(toast, at: 0)
        }
        if let haptic = toast.haptics {
            HapticManager.shared.notify(haptic)
        }
        scheduleTimer(for: toast)
    }

    private func scheduleTimer(for toast: BandzToast) {
        guard let ttl = toast.ttl, ttl != .infinity else { return }
        let toastId = toast.id
        let task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(ttl))
            guard !Task.isCancelled else { return }
            self?.dismiss(id: toastId)
        }
        dismissTasks[toastId] = task
    }

    private func showNextIfNeeded() {
        if activeToasts.count < 2, let next = queue.popLast() {
            insertToast(next)
        }
    }
}
