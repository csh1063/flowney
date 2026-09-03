import Foundation

public struct CurrencyOption: Identifiable, Equatable, Sendable {
    public var code: String
    public var name: String
    public var symbol: String

    public var id: String { code }

    public init(code: String, name: String, symbol: String) {
        self.code = code
        self.name = name
        self.symbol = symbol
    }
}

public enum CurrencyCatalog {
    public static let all: [CurrencyOption] = [
        .init(code: "KRW", name: "대한민국 원", symbol: "₩"),
        .init(code: "USD", name: "미국 달러", symbol: "$"),
        .init(code: "EUR", name: "유로", symbol: "€"),
        .init(code: "JPY", name: "일본 엔", symbol: "¥"),
        .init(code: "GBP", name: "영국 파운드", symbol: "£"),
        .init(code: "CHF", name: "스위스 프랑", symbol: "CHF"),
        .init(code: "CNY", name: "중국 위안", symbol: "¥"),
        .init(code: "HKD", name: "홍콩 달러", symbol: "HK$"),
        .init(code: "TWD", name: "대만 달러", symbol: "NT$"),
        .init(code: "THB", name: "태국 바트", symbol: "฿"),
        .init(code: "VND", name: "베트남 동", symbol: "₫"),
        .init(code: "SGD", name: "싱가포르 달러", symbol: "S$"),
        .init(code: "MYR", name: "말레이시아 링깃", symbol: "RM"),
        .init(code: "PHP", name: "필리핀 페소", symbol: "₱"),
        .init(code: "IDR", name: "인도네시아 루피아", symbol: "Rp"),
        .init(code: "INR", name: "인도 루피", symbol: "₹"),
        .init(code: "AUD", name: "호주 달러", symbol: "A$"),
        .init(code: "NZD", name: "뉴질랜드 달러", symbol: "NZ$"),
        .init(code: "CAD", name: "캐나다 달러", symbol: "C$"),
        .init(code: "MXN", name: "멕시코 페소", symbol: "MX$"),
        .init(code: "BRL", name: "브라질 헤알", symbol: "R$"),
        .init(code: "SEK", name: "스웨덴 크로나", symbol: "kr"),
        .init(code: "NOK", name: "노르웨이 크로네", symbol: "kr"),
        .init(code: "DKK", name: "덴마크 크로네", symbol: "kr"),
        .init(code: "ISK", name: "아이슬란드 크로나", symbol: "kr"),
        .init(code: "PLN", name: "폴란드 즈워티", symbol: "zł"),
        .init(code: "CZK", name: "체코 코루나", symbol: "Kč"),
        .init(code: "HUF", name: "헝가리 포린트", symbol: "Ft"),
        .init(code: "RON", name: "루마니아 레우", symbol: "lei"),
        .init(code: "TRY", name: "튀르키예 리라", symbol: "₺"),
        .init(code: "RUB", name: "러시아 루블", symbol: "₽"),
        .init(code: "ZAR", name: "남아프리카공화국 랜드", symbol: "R"),
        .init(code: "AED", name: "아랍에미리트 디르함", symbol: "AED"),
        .init(code: "SAR", name: "사우디아라비아 리얄", symbol: "SAR"),
        .init(code: "QAR", name: "카타르 리얄", symbol: "QAR"),
        .init(code: "ILS", name: "이스라엘 셰켈", symbol: "₪"),
        .init(code: "EGP", name: "이집트 파운드", symbol: "E£"),
        .init(code: "MAD", name: "모로코 디르함", symbol: "MAD"),
        .init(code: "KHR", name: "캄보디아 리엘", symbol: "៛"),
        .init(code: "LAK", name: "라오스 킵", symbol: "₭"),
        .init(code: "MMK", name: "미얀마 짯", symbol: "K"),
        .init(code: "MOP", name: "마카오 파타카", symbol: "MOP$"),
        .init(code: "NPR", name: "네팔 루피", symbol: "Rs"),
        .init(code: "LKR", name: "스리랑카 루피", symbol: "Rs"),
        .init(code: "FJD", name: "피지 달러", symbol: "FJ$"),
        .init(code: "ARS", name: "아르헨티나 페소", symbol: "$"),
        .init(code: "CLP", name: "칠레 페소", symbol: "$"),
        .init(code: "COP", name: "콜롬비아 페소", symbol: "$"),
        .init(code: "PEN", name: "페루 솔", symbol: "S/"),
    ]

    public static func option(for code: String) -> CurrencyOption? {
        all.first { $0.code == code }
    }

    public static func symbol(for code: String) -> String {
        option(for: code)?.symbol ?? code
    }
}
