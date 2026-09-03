import AuthenticationServices
import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct AuthView: View {
    @Bindable var store: StoreOf<AuthFeature>
    @State private var currentRawNonce: String?

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Waypin")
                    .font(WaypinFont.screenTitle)
                Text("여행의 모든 순간을 하나의 경로로")
                    .font(WaypinFont.body)
                    .foregroundStyle(WaypinTheme.textSecondary)
            }

            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    let rawNonce = AppleNonce.randomNonceString()
                    currentRawNonce = rawNonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = AppleNonce.sha256(rawNonce)
                } onCompletion: { result in
                    handleAppleCompletion(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)

                Button {
                    store.send(.signInWithGoogleTapped)
                } label: {
                    HStack {
                        Image(systemName: "g.circle.fill")
                        Text("Google로 계속하기")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
            }
            .padding(.horizontal, 24)

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(WaypinFont.caption)
                    .foregroundStyle(WaypinTheme.error)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WaypinTheme.background)
        .ignoresSafeArea(edges: .bottom)
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case let .success(authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8),
                let rawNonce = currentRawNonce
            else {
                store.send(.appleSignInCompleted(.failure(AppleSignInError.missingIdentityToken)))
                return
            }
            store.send(.appleSignInCompleted(.success(.init(identityToken: identityToken, rawNonce: rawNonce))))
        case let .failure(error):
            store.send(.appleSignInCompleted(.failure(error)))
        }
    }
}

private enum AppleSignInError: Error {
    case missingIdentityToken
}
