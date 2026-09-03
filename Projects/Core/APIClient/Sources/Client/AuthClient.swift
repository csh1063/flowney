import ComposableArchitecture
import Foundation
import Supabase

@DependencyClient
public struct AuthClient: Sendable {
    public var currentSession: @Sendable () async -> Session?
    public var sessionChanges: @Sendable () -> AsyncStream<Session?> = { AsyncStream { $0.finish() } }
    public var signInWithIdToken: @Sendable (_ provider: Provider, _ idToken: String, _ nonce: String?) async throws -> Session
    public var signOut: @Sendable () async throws -> Void

    public enum Provider: Sendable {
        case apple
        case google
    }
}

extension AuthClient: DependencyKey {
    public static let liveValue: AuthClient = {
        let client = SupabaseClientProvider.shared

        return AuthClient(
            currentSession: {
                try? await client.auth.session
            },
            sessionChanges: {
                AsyncStream { continuation in
                    let task = Task {
                        for await state in client.auth.authStateChanges {
                            continuation.yield(state.session)
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            },
            signInWithIdToken: { provider, idToken, nonce in
                try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: provider.supabaseProvider,
                        idToken: idToken,
                        nonce: nonce
                    )
                )
            },
            signOut: {
                try await client.auth.signOut()
            }
        )
    }()
}

extension AuthClient.Provider {
    fileprivate var supabaseProvider: OpenIDConnectCredentials.Provider {
        switch self {
        case .apple: return .apple
        case .google: return .google
        }
    }
}

extension DependencyValues {
    public var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
