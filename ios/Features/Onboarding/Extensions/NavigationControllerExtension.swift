//
//  NavigationControllerExtension.swift
//  Bandz
//
//  Created by Felipe Canhameiro on 24/06/25.
//

import SwiftUI
import UIKit

// MARK: - Navigation Controller Extension for Swipe Back

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

// MARK: - SwiftUI View Extension for Navigation Swipe

extension View {
    /// Enables native swipe back even with navigationBarBackButtonHidden(true)
    func enableSwipeBack() -> some View {
        self.background(
            NavigationControllerAccessor()
        )
    }

    /// Disables the interactive pop gesture (swipe back) for this view
    func disableSwipeBack() -> some View {
        self.background(
            SwipeBackDisabler()
        )
    }
}

// MARK: - Navigation Controller Accessor

private struct NavigationControllerAccessor: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let navigationController = uiViewController.navigationController {
            navigationController.interactivePopGestureRecognizer?.delegate = navigationController
        }
    }
}

private struct SwipeBackDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
}