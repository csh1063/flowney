import ComposableArchitecture
import Foundation

/// 공유 링크함 리스트 행에 보여줄 미리보기 정보. 이름/이미지를 우선으로 두고, 나라/도시는
/// 주소 문자열을 휴리스틱으로 쪼갠 것이라 확실하지 않으면 nil로 둔다.
public struct LinkPreview: Equatable, Sendable {
    public var name: String?
    public var imageURLString: String?
    public var country: String?
    public var city: String?

    public init(name: String? = nil, imageURLString: String? = nil, country: String? = nil, city: String? = nil) {
        self.name = name
        self.imageURLString = imageURLString
        self.country = country
        self.city = city
    }
}

public enum LinkPreviewError: Error, Equatable {
    case invalidURL
    case requestFailed
}

/// 공유받은 링크(구글맵 등)의 og:title/og:image 메타태그를 직접 fetch해서 미리보기를
/// 만든다. 서버(mock-serverless)를 거치지 않는다 — API 키가 필요 없는 공개 정보라
/// 클라이언트에서 바로 가져오는 게 더 단순하다.
///
/// 실측 확인: 구글맵 URL에 실제 장소 데이터 해시(`data=!3m1!4b1!...`)가 포함돼 있으면(진짜
/// 공유 링크가 리다이렉트되는 형태가 이거다) og:title이 "이름 · 전체주소" 형태로, og:image가
/// 실제 장소 사진으로 채워진다. 일반 모바일 브라우저 UA로는 JS 앱 셸만 오고 메타태그가
/// 비어있어서, 크롤러류 User-Agent를 써야 서버가 채워진 메타태그를 내려준다.
@DependencyClient
public struct LinkPreviewClient: Sendable {
    public var fetch: @Sendable (_ url: String) async throws -> LinkPreview
}

extension LinkPreviewClient: DependencyKey {
    public static let liveValue: LinkPreviewClient = {
        LinkPreviewClient(
            fetch: { urlString in
                guard let url = URL(string: urlString) else { throw LinkPreviewError.invalidURL }

                var request = URLRequest(url: url)
                request.setValue("WhatsApp/2.23.20.0", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await URLSession.shared.data(for: request)
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200 ..< 300).contains(httpResponse.statusCode),
                    let html = String(data: data, encoding: .utf8)
                else {
                    throw LinkPreviewError.requestFailed
                }

                return LinkPreviewParser.parse(html: html)
            }
        )
    }()
}

extension DependencyValues {
    public var linkPreviewClient: LinkPreviewClient {
        get { self[LinkPreviewClient.self] }
        set { self[LinkPreviewClient.self] = newValue }
    }
}

enum LinkPreviewParser {
    /// 구글맵 og:title은 "이름 · 전체주소" 형태(가운데 점 구분자), 주소는 콤마로 나뉘고
    /// 마지막 조각이 나라다. 그 바로 앞 조각은 보통 "우편번호 도시" 형태라 숫자만 걸러내면
    /// 도시가 남는다 — 나라마다 주소 형식이 달라서 100% 정확하진 않은 휴리스틱이라, 애매하면
    /// nil로 둔다(이름/이미지를 우선한다).
    static func parse(html: String) -> LinkPreview {
        let title = metaContent(property: "og:title", from: html).map(decodeHTMLEntities)
        let image = metaContent(property: "og:image", from: html).map(decodeHTMLEntities)

        // 장소별 데이터가 없으면 구글이 그냥 "Google Maps" 제네릭 타이틀을 준다 — 그건 못 쓴다.
        guard let title, !title.isEmpty, title != "Google Maps" else {
            return LinkPreview(imageURLString: image)
        }

        let titleParts = title.components(separatedBy: " · ")
        let name = titleParts.first
        var country: String?
        var city: String?

        if titleParts.count > 1 {
            let addressParts = titleParts[1]
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            country = addressParts.last

            if addressParts.count >= 2 {
                let cityCandidate = addressParts[addressParts.count - 2]
                let withoutDigits = cityCandidate
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.allSatisfy(\.isNumber) }
                    .joined(separator: " ")
                city = withoutDigits.isEmpty ? nil : withoutDigits
            }
        }

        return LinkPreview(name: name, imageURLString: image, country: country, city: city)
    }

    private static func metaContent(property: String, from html: String) -> String? {
        // <meta content="..." property="og:x"> / <meta property="og:x" content="..."> 둘 다
        // 나올 수 있어서 두 패턴 다 시도한다.
        let patterns = [
            "<meta[^>]*property=\"\(property)\"[^>]*content=\"([^\"]*)\"",
            "<meta[^>]*content=\"([^\"]*)\"[^>]*property=\"\(property)\"",
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, range: range), let matchRange = Range(match.range(at: 1), in: html) {
                return String(html[matchRange])
            }
        }
        return nil
    }

    private static func decodeHTMLEntities(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }
}
