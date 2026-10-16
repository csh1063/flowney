import ComposableArchitecture
import Foundation
import Network

@DependencyClient
public struct NetworkMonitorClient: Sendable {
    public var connectivityChanges: @Sendable () -> AsyncStream<Bool> = { AsyncStream { $0.finish() } }
}

extension NetworkMonitorClient: DependencyKey {
    public static let liveValue: NetworkMonitorClient = {
        NetworkMonitorClient(
            connectivityChanges: {
                AsyncStream { continuation in
                    let monitor = NWPathMonitor()
                    monitor.pathUpdateHandler = { path in
                        continuation.yield(path.status == .satisfied)
                    }
                    monitor.start(queue: DispatchQueue(label: "com.flowney.networkMonitor"))
                    continuation.onTermination = { _ in monitor.cancel() }
                }
            }
        )
    }()
}

extension DependencyValues {
    public var networkMonitorClient: NetworkMonitorClient {
        get { self[NetworkMonitorClient.self] }
        set { self[NetworkMonitorClient.self] = newValue }
    }
}
