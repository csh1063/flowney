import GoogleSignIn
import UIKit

enum GoogleSignInClient {
    enum SignInError: Error {
        case missingIdToken
        case noPresentingViewController
    }

    @MainActor
    static func signIn() async throws -> String {
        guard let presenting = topViewController() else {
            throw SignInError.noPresentingViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = result.user.idToken?.tokenString else {
            throw SignInError.missingIdToken
        }
        return idToken
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)

        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
