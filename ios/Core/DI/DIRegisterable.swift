import Foundation

/// Protocol for services that can register themselves with the DI container
protocol DIRegisterable {
    /// Register the service with the DIContainer
    /// - Parameter container: The DIContainer to register with
    static func registerDependencies(in container: DIContainer)
}