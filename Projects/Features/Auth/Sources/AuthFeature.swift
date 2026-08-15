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
        /// 스플래시 화면을 띄우는 동안의 상태 — 최초 세션 조회(`authClient.currentSession()`)
        /// 결과가 오기 전까지 true. 이게 없으면 `isSignedIn`이 기본 `false`라서, 로그인된
        /// 사용자도 앱을 켤 때마다 로그인 화면이 잠깐 보였다가 세션이 확인되고 나서야
        /// 메인으로 넘어가는 깜빡임이 생긴다.
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
                    // 로컬에 캐시된 세션이면 조회가 거의 즉시 끝나서 스플래시가 한 프레임도
                    // 안 되게 스쳐 지나간다 — 최소 노출 시간(3초)을 세션 조회와 동시에
                    // 돌려서, 조회가 더 빨리 끝나도 스플래시는 최소 이만큼 보이게 한다.
                    async let sessionResult = authClient.currentSession()
                    async let minimumSplashDelay: Void? = try? Task.sleep(for: .seconds(3))
                    let session = await sessionResult
                    _ = await minimumSplashDelay
                    // 세션이 nil이어도 "확인 결과 없음"을 명시적으로 알려야 스플래시를
                    // 내리고 로그인 화면으로 넘어갈 수 있다 — 있을 때만 보내면 로그아웃
                    // 상태에서 영원히 스플래시에 머무른다.
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
