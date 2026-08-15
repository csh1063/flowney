import SwiftUI

extension View {
    /// 인라인 내비게이션 타이틀을 왼쪽 정렬로 보여준다. SwiftUI 기본 `.inline` 모드는 타이틀을
    /// 가운데 정렬하므로, principal 툴바 아이템을 툴바 폭 전체로 펼쳐서 왼쪽에 붙인다.
    ///
    /// 탭 루트/`navigationDestination`으로 들어가는 화면(뒤로가기만 있거나 버튼이 오른쪽에만
    /// 있어도)은 전부 이걸 쓴다 — `.sheet`/`.fullScreenCover`로 "present"되는 화면만 기본
    /// 가운데 정렬(`.navigationBarTitleDisplayMode(.inline)`)을 그대로 둔다.
    public func waypinLeadingTitle(_ title: String) -> some View {
        navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(WaypinFont.sectionHeader)
                        .foregroundStyle(WaypinTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
    }
}
