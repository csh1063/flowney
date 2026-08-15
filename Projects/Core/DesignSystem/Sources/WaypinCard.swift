import SwiftUI

/// 스톡 `List`/`Form` 행 대신 쓰는 카드 컨테이너 — 배경/구분선을 걷어낸 자리에 이걸로
/// 감싸서 "커스텀 디자인" 느낌을 낸다.
private struct WaypinCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(WaypinSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous)
                    .fill(WaypinTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous)
                    .stroke(WaypinTheme.divider, lineWidth: 1)
            )
    }
}

extension View {
    public func waypinCard() -> some View {
        modifier(WaypinCardModifier())
    }

    /// `.waypinCard()`로 감싼 콘텐츠를 `List` 행으로 쓸 때, 스톡 행 배경/구분선/기본
    /// 인셋을 걷어내서 카드만 보이게 한다.
    public func waypinCardListRow() -> some View {
        listRowInsets(EdgeInsets(top: WaypinSpacing.xs, leading: WaypinSpacing.lg, bottom: WaypinSpacing.xs, trailing: WaypinSpacing.lg))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
