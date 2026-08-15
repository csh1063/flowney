import SwiftUI

/// 화면마다 제각각이던 폰트 크기/굵기를 역할별로 정리한 타이포그래피 스케일.
/// 고정 포인트 크기 대신 시스템 텍스트 스타일(`.title2`, `.body` 등) 기반으로 만들어서
/// 사용자가 기기에서 글자 크기(Dynamic Type)를 키워도 그대로 따라간다 — 숫자를 직접
/// 박아넣으면 이 접근성 기능이 깨진다.
public enum WaypinFont {
    /// 화면 제목급(예: 여행 이름, 큰 헤더)
    public static let screenTitle = Font.system(.title2, weight: .bold)
    /// 섹션 헤더(예: "여행 기간", "카테고리별")
    public static let sectionHeader = Font.system(.headline, weight: .semibold)
    /// 기본 본문
    public static let body = Font.system(.body, weight: .regular)
    /// 강조가 필요한 본문(리스트 행 제목 등)
    public static let bodyEmphasis = Font.system(.body, weight: .semibold)
    /// 보조 설명 텍스트
    public static let caption = Font.system(.caption, weight: .regular)
    /// 강조된 보조 텍스트(배지 라벨 등)
    public static let captionEmphasis = Font.system(.caption2, weight: .semibold)
    /// 금액처럼 자릿수 정렬이 중요한 숫자
    public static let numeric = Font.system(.body, design: .rounded, weight: .semibold)
}
