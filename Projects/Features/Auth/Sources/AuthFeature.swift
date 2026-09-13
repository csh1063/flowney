import APIClient
import AuthenticationServices
import ComposableArchitecture
import Foundation
import GoogleSignIn
import Models
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
                    async let minimumSplashDelay: Void? = try? Task.sleep(for: .seconds(4.1))
                    let session = await sessionResult
                    _ = await minimumSplashDelay
                    await send(.sessionChanged(session))
                    for await session in authClient.sessionChanges() {
                        await send(.sessionChanged(session))
                    }
                }

            case let .appleSignInCompleted(.success(credential)):
                FlowneyLog.debug("애플 로그인 성공(자격 증명), 세션 교환 시작", category: .auth)
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
                if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                    FlowneyLog.debug("애플 로그인 취소됨", category: .auth)
                    state.errorMessage = nil
                } else {
                    FlowneyLog.error("애플 로그인 실패: \(error)", category: .auth)
                    state.errorMessage = "애플 로그인에 실패했어요. 다시 시도해주세요."
                }
                return .none

            case .signInWithGoogleTapped:
                FlowneyLog.debug("구글 로그인 시작", category: .auth)
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
                FlowneyLog.debug("구글 idToken 획득, 세션 교환 시작", category: .auth)
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
                if let signInError = error as? GIDSignInError, signInError.code == .canceled {
                    FlowneyLog.debug("구글 로그인 취소됨", category: .auth)
                    state.errorMessage = nil
                } else {
                    FlowneyLog.error("구글 로그인 실패: \(error)", category: .auth)
                    state.errorMessage = "구글 로그인에 실패했어요. 다시 시도해주세요."
                }
                return .none

            case let .supabaseSignInResponse(.success(session)):
                FlowneyLog.debug("Supabase 세션 교환 성공 user=\(session.user.id)", category: .auth)
                state.isLoading = false
                state.errorMessage = nil
                state.session = session
                if !state.isSignedIn { state.isSignedIn = true }
                return .send(.delegate(.signedIn(session)))

            case let .supabaseSignInResponse(.failure(error)):
                FlowneyLog.error("Supabase 세션 교환 실패: \(error)", category: .auth)
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .signOutTapped:
                FlowneyLog.debug("로그아웃 시작", category: .auth)
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
                FlowneyLog.debug("로그아웃 성공", category: .auth)
                state.isLoading = false
                state.session = nil
                if state.isSignedIn { state.isSignedIn = false }
                return .send(.delegate(.signedOut))

            case let .signOutResponse(.failure(error)):
                FlowneyLog.error("로그아웃 실패: \(error)", category: .auth)
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .sessionChanged(session):
                state.isCheckingSession = false
                state.session = session
                let signedIn = session.map { !$0.isExpired } ?? false
                FlowneyLog.debug("세션 변경 signedIn=\(signedIn)", category: .auth)
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
