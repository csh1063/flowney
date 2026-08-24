import APIClient
import ComposableArchitecture
import Foundation
import Supabase

@Reducer
public struct AuthFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var session: Session?
        public var isSignedIn: Bool = false
        public var isCheckingSession: Bool = true
        public var isLoading: Bool = false
        public var errorMessage: String?

        public init(session: Session? = nil) {
            self.session = session
            self.isSignedIn = session.map { !$0.isExpired } ?? false
        }
    }

    public enum Action {
        case onAppear
        case appleSignInCompleted(Result<AppleNonce.Credential, any Error>)
        case signInWithGoogleTapped
        case signOutTapped
        case googleIdTokenResponse(Result<String, any Error>)
        case supabaseSignInResponse(Result<Session, any Error>)
        case signOutResponse(Result<Void, any Error>)
        case sessionChanged(Session?)
        case delegate(Delegate)

        public enum Delegate {
            case signedIn(Session)
            case signedOut
        }
    }

    @Dependency(\.authClient) var authClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    async let sessionResult = authClient.currentSession()
                    async let minimumSplashDelay: Void? = try? Task.sleep(for: .seconds(1))
                    let session = await sessionResult
                    _ = await minimumSplashDelay
                    await send(.sessionChanged(session))
                    for await session in authClient.sessionChanges() {
                        await send(.sessionChanged(session))
                    }
                }

            case let .appleSignInCompleted(.success(credential)):
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let session = try await authClient.signInWithIdToken(
                            .apple, credential.identityToken, credential.rawNonce
                        )
                        await send(.supabaseSignInResponse(.success(session)))
                    } catch {
                        await send(.supabaseSignInResponse(.failure(error)))
                    }
                }

            case let .appleSignInCompleted(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .signInWithGoogleTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let idToken = try await GoogleSignInClient.signIn()
                        await send(.googleIdTokenResponse(.success(idToken)))
                    } catch {
                        await send(.googleIdTokenResponse(.failure(error)))
                    }
                }

            case let .googleIdTokenResponse(.success(idToken)):
                return .run { send in
                    do {
                        let session = try await authClient.signInWithIdToken(.google, idToken, nil)
                        await send(.supabaseSignInResponse(.success(session)))
                    } catch {
                        await send(.supabaseSignInResponse(.failure(error)))
                    }
                }

            case let .googleIdTokenResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .supabaseSignInResponse(.success(session)):
                state.isLoading = false
                state.errorMessage = nil
                state.session = session
                if !state.isSignedIn { state.isSignedIn = true }
                return .send(.delegate(.signedIn(session)))

            case let .supabaseSignInResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .signOutTapped:
                state.isLoading = true
                return .run { send in
                    do {
                        try await authClient.signOut()
                        await send(.signOutResponse(.success(())))
                    } catch {
                        await send(.signOutResponse(.failure(error)))
                    }
                }

            case .signOutResponse(.success):
                state.isLoading = false
                state.session = nil
                if state.isSignedIn { state.isSignedIn = false }
                return .send(.delegate(.signedOut))

            case let .signOutResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .sessionChanged(session):
                state.isCheckingSession = false
                state.session = session
                let signedIn = session.map { !$0.isExpired } ?? false
                if state.isSignedIn != signedIn {
                    state.isSignedIn = signedIn
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
