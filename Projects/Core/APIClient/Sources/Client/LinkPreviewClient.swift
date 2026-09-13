import ComposableArchitecture
import Foundation
import Models

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

@DependencyClient
public struct LinkPreviewClient: Sendable {
    public var fetch: @Sendable (_ url: String) async throws -> LinkPreview
}

extension LinkPreviewClient: DependencyKey {
    public static let liveValue: LinkPreviewClient = {
        LinkPreviewClient(
            fetch: { urlString in
                FlowneyLog.debug("link preview 요청 url=\(urlString)", category: .network)
                guard let url = URL(string: urlString) else { throw LinkPreviewError.invalidURL }

                var request = URLRequest(url: url)
                request.setValue("WhatsApp/2.23.20.0", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await URLSession.shared.data(for: request)
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200 ..< 300).contains(httpResponse.statusCode),
                    let html = String(data: data, encoding: .utf8)
                else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    FlowneyLog.error("link preview HTTP \(statusCode)", category: .network)
                    throw LinkPreviewError.requestFailed
                }

                let preview = LinkPreviewParser.parse(html: html)
                FlowneyLog.debug("link preview 파싱 결과 name=\(String(describing: preview.name))", category: .network)
                return preview
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
    static func parse(html: String) -> LinkPreview {
        let title = metaContent(property: "og:title", from: html).map(decodeHTMLEntities)
        let image = metaContent(property: "og:image", from: html).map(decodeHTMLEntities)

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
