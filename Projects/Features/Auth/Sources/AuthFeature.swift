import APIClient
import ComposableArchitecture
import Foundation
import Supabase

@Reducer
public struct AuthFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var session: Session?
        /// `session`은 토큰 갱신마다 값이 바뀌어서(Observation이 매번 리렌더를 유발) 화면 분기에
        /// 직접 쓰지 않는다. 실제 로그인/로그아웃 "전환"이 있을 때만 값이 바뀌는 안정적인
        /// 플래그를 따로 두고, RootView는 이걸로만 최상위 화면을 분기한다.
        public var isSignedIn: Bool = false
        public var isLoading: Bool = false
        public var errorMessage: String?

        public init(session: Session? = nil) {
            self.session = session
            self.isSignedIn = session.map { !$0.isExpired } ?? false
        }
    }

    public enum Action {
        case onAppear
        /// SwiftUI의 `SignInWithAppleButton`이 프레젠테이션/딜리게이트를 직접 처리하므로,
        /// 뷰가 완료 결과를 여기로 바로 전달한다.
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
                    if let session = await authClient.currentSession() {
                        await send(.sessionChanged(session))
                    }
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
