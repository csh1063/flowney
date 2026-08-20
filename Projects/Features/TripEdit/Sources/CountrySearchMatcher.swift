import Foundation

/// 나라 이름 검색 — 일반 부분 문자열 매칭에 더해 한글 초성 검색과, 받침 없는 완성형
/// 음절의 "받침 무시" 매칭("이"가 "일본"에 매칭)까지 지원한다.
enum CountrySearchMatcher {
    private static let choseongTable: [Character] =
        ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]

    private static func decompose(_ char: Character) -> (initial: Int, medial: Int, final: Int)? {
        guard let scalar = char.unicodeScalars.first,
              (0xAC00...0xD7A3).contains(scalar.value)
        else { return nil }
        let offset = Int(scalar.value) - 0xAC00
        return (offset / (21 * 28), (offset / 28) % 21, offset % 28)
    }

    private static func isChoseongJamo(_ char: Character) -> Bool {
        choseongTable.contains(char)
    }

    private static func charMatches(queryChar: Character, nameChar: Character) -> Bool {
        if isChoseongJamo(queryChar) {
            guard let n = decompose(nameChar) else { return false }
            return choseongTable[n.initial] == queryChar
        }
        guard let q = decompose(queryChar) else { return queryChar == nameChar }
        guard let n = decompose(nameChar), q.initial == n.initial, q.medial == n.medial else { return false }
        return q.final == 0 || q.final == n.final
    }

    // 초성 자모로만 이루어진 검색어는 2글자 미만이면 매칭이 너무 광범위해지므로 결과 없음 처리.
    static func matches(query: String, name: String) -> Bool {
        let q = Array(query)
        let n = Array(name)
        guard !q.isEmpty, q.count <= n.count else { return false }
        if q.allSatisfy(isChoseongJamo), q.count < 2 { return false }
        for start in 0...(n.count - q.count) {
            if (0..<q.count).allSatisfy({ charMatches(queryChar: q[$0], nameChar: n[start + $0]) }) {
                return true
            }
        }
        return false
    }
}
