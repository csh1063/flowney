import SwiftUI

/// 카드 콘텐츠를 왼쪽으로 스와이프하면, 카드와 똑같은 둥근 모서리 안에서 삭제 버튼이
/// 드러나는 컨테이너.
///
/// 스톡 `List`의 `.swipeActions`/`.onDelete`를 쓰면 삭제 버튼이 리스트 행의 실제(꽉 찬)
/// 너비를 기준으로 그려져서, `waypinCard()`처럼 여백을 두고 인셋된 콘텐츠보다 항상 더 넓게
/// 삐져나온다 — `listRowInsets`는 콘텐츠 위치만 옮길 뿐 스와이프 버튼 자체의 프레임에는
/// 영향을 못 준다. 그래서 삭제 버튼을 카드와 한 몸(같은 `clipShape`)으로 직접 그린다.
public struct SwipeToDeleteCard<Content: View>: View {
    let onDelete: () -> Void
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var committedOffset: CGFloat = 0
    @GestureState private var dragTranslation: CGFloat = 0

    private let actionWidth: CGFloat = 76

    public init(
        onDelete: @escaping () -> Void,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onDelete = onDelete
        self.onTap = onTap
        self.content = content
    }

    private var offset: CGFloat {
        max(-actionWidth, min(0, committedOffset + dragTranslation))
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { committedOffset = 0 }
                onDelete()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("삭제")
                        .font(WaypinFont.caption)
                }
                .foregroundStyle(.white)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
            }
            .background(WaypinTheme.error)

            content()
                .contentShape(Rectangle())
                .onTapGesture {
                    if committedOffset == 0 {
                        onTap()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) { committedOffset = 0 }
                    }
                }
                .offset(x: offset)
        }
        .clipShape(RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 12)
                .updating($dragTranslation) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    let target = committedOffset + value.translation.width
                    withAnimation(.easeOut(duration: 0.2)) {
                        committedOffset = target < -actionWidth / 2 ? -actionWidth : 0
                    }
                }
        )
    }
}
