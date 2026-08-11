import CryptoKit
import Foundation

/// SwiftUI의 `SignInWithAppleButton`이 이미 프레젠테이션/딜리게이트 처리를 해주므로,
/// 여기서는 Apple의 재전송 공격 방지 요구사항(request에 해시 nonce, 검증에 raw nonce)에
/// 필요한 nonce 생성/해싱만 담당한다.
public enum AppleNonce {
    public struct Credential: Sendable {
        public var identityToken: String
        public var rawNonce: String

        public init(identityToken: String, rawNonce: String) {
            self.identityToken = identityToken
            self.rawNonce = rawNonce
        }
    }

    public static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
            precondition(status == errSecSuccess, "난수 생성 실패: \(status)")

            for byte in randomBytes where remainingLength > 0 {
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    public static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
