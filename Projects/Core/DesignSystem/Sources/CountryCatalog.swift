import Foundation

public struct CountryOption: Identifiable, Equatable, Sendable {
    public var code: String
    public var name: String
    public var defaultColorHex: String

    public var id: String { code }

    public init(code: String, name: String, defaultColorHex: String) {
        self.code = code
        self.name = name
        self.defaultColorHex = defaultColorHex
    }
}

public enum CountryCatalog {
    public static let all: [CountryOption] = [
        .init(code: "KR", name: "대한민국", defaultColorHex: "#2c3e50"),
        .init(code: "JP", name: "일본", defaultColorHex: "#b8202e"),
        .init(code: "CN", name: "중국", defaultColorHex: "#c8452e"),
        .init(code: "TW", name: "대만", defaultColorHex: "#1e88a8"),
        .init(code: "HK", name: "홍콩", defaultColorHex: "#8e44ad"),
        .init(code: "TH", name: "태국", defaultColorHex: "#e67e22"),
        .init(code: "VN", name: "베트남", defaultColorHex: "#c0392b"),
        .init(code: "SG", name: "싱가포르", defaultColorHex: "#16a085"),
        .init(code: "MY", name: "말레이시아", defaultColorHex: "#27ae60"),
        .init(code: "PH", name: "필리핀", defaultColorHex: "#2980b9"),
        .init(code: "ID", name: "인도네시아", defaultColorHex: "#d35400"),
        .init(code: "NL", name: "네덜란드", defaultColorHex: "#c8452e"),
        .init(code: "FR", name: "프랑스", defaultColorHex: "#1e3a5f"),
        .init(code: "CH", name: "스위스", defaultColorHex: "#b8202e"),
        .init(code: "DE", name: "독일", defaultColorHex: "#34495e"),
        .init(code: "IT", name: "이탈리아", defaultColorHex: "#27ae60"),
        .init(code: "ES", name: "스페인", defaultColorHex: "#e74c3c"),
        .init(code: "PT", name: "포르투갈", defaultColorHex: "#16a085"),
        .init(code: "AT", name: "오스트리아", defaultColorHex: "#8e44ad"),
        .init(code: "BE", name: "벨기에", defaultColorHex: "#f39c12"),
        .init(code: "GB", name: "영국", defaultColorHex: "#2c3e50"),
        .init(code: "IE", name: "아일랜드", defaultColorHex: "#27ae60"),
        .init(code: "GR", name: "그리스", defaultColorHex: "#2980b9"),
        .init(code: "TR", name: "튀르키예", defaultColorHex: "#c0392b"),
        .init(code: "CZ", name: "체코", defaultColorHex: "#34495e"),
        .init(code: "HU", name: "헝가리", defaultColorHex: "#c8452e"),
        .init(code: "PL", name: "폴란드", defaultColorHex: "#e74c3c"),
        .init(code: "NO", name: "노르웨이", defaultColorHex: "#1e3a5f"),
        .init(code: "SE", name: "스웨덴", defaultColorHex: "#2980b9"),
        .init(code: "FI", name: "핀란드", defaultColorHex: "#8e44ad"),
        .init(code: "IS", name: "아이슬란드", defaultColorHex: "#16a085"),
        .init(code: "US", name: "미국", defaultColorHex: "#2c3e50"),
        .init(code: "CA", name: "캐나다", defaultColorHex: "#c0392b"),
        .init(code: "MX", name: "멕시코", defaultColorHex: "#27ae60"),
        .init(code: "AU", name: "호주", defaultColorHex: "#f39c12"),
        .init(code: "NZ", name: "뉴질랜드", defaultColorHex: "#2980b9"),
        .init(code: "AE", name: "아랍에미리트", defaultColorHex: "#d35400"),
    ]

    public static func option(for code: String) -> CountryOption? {
        all.first { $0.code == code }
    }

    public static func flagEmoji(for code: String) -> String {
        let base: UInt32 = 127_397
        var scalars = String.UnicodeScalarView()
        for scalar in code.uppercased().unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                scalars.append(flagScalar)
            }
        }
        return String(scalars)
    }
}
