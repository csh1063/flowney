import SwiftUI

public struct SwipeToDeleteCard<Content: View>: View {
    let id: AnyHashable
    @Binding var revealedID: AnyHashable?
    let onDelete: () -> Void
    let onEdit: (() -> Void)?
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var committedOffset: CGFloat = 0
    @State private var hasTriggeredAction = false
    @GestureState private var dragTranslation: CGFloat = 0

    private let actionWidth: CGFloat = 76

    public init(
        id: AnyHashable,
        revealedID: Binding<AnyHashable?>,
        onDelete: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        onTap: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self._revealedID = revealedID
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.onTap = onTap
        self.content = content
    }

    private var maxOffset: CGFloat { onEdit != nil ? actionWidth : 0 }

    private var offset: CGFloat {
        max(-actionWidth, min(maxOffset, committedOffset + dragTranslation))
    }

    // 카드가 열려있는지 여부
    private var isRevealed: Bool {
        committedOffset != 0
    }

    public var body: some View {
        ZStack {
            // 0. 카드 배경 — 버튼이 보이든 콘텐츠가 보이든 항상 이 하나의 둥근 배경 위에 그려져서,
            // 버튼과 콘텐츠가 각자 따로 둥근 모양을 갖는 대신 "카드 하나" 실루엣 안에 같이 들어가게 한다.
            RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous)
                .fill(FlowneyTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous)
                        .stroke(FlowneyTheme.divider, lineWidth: 1)
                )

            // 1. 액션 버튼 레이어 — 지금 안 쓰는 버튼은 hit-testing만 끄는 게 아니라
            // 아예 뷰 트리에서 빼서, 어떤 경우에도 반대쪽 버튼이 눌릴 수 없게 한다.
            Group {
                if committedOffset < 0 {
                    HStack {
                        Spacer()
                        Button {
                            handleAction(onDelete)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("삭제")
                                    .font(FlowneyFont.caption)
                            }
                            .foregroundStyle(.white)
                            .frame(width: actionWidth)
                            .frame(maxHeight: .infinity)
                            .background(FlowneyTheme.error)
                        }
                    }
                } else if committedOffset > 0, let onEdit {
                    HStack {
                        Button {
                            handleAction(onEdit)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "pencil")
                                Text("수정")
                                    .font(FlowneyFont.caption)
                            }
                            .foregroundStyle(.white)
                            .frame(width: actionWidth)
                            .frame(maxHeight: .infinity)
                            .background(FlowneyTheme.fill)
                        }
                        Spacer()
                    }
                }
            }

            // 2. 콘텐츠 레이어 — 자기 배경/둥근 모서리는 없고, 위 카드 배경 위에 그냥 얹힌다
            content()
                .contentShape(Rectangle()) // 투명 영역도 터치 감지되도록 설정
                .offset(x: offset)
                .onTapGesture {
                    if isRevealed {
                        // 열려있을 때 카드를 누르면 닫기만 함
                        withAnimation(.easeInOut(duration: 0.2)) {
                            committedOffset = 0
                        }
                        if revealedID == id { revealedID = nil }
                    } else {
                        // 완전히 닫혀있을 때만 기존 onTap 실행
                        onTap()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .updating($dragTranslation) { value, state, _ in
                            // 대각선/세로 스크롤 시 스와이프 미동작하도록 X축 우세할 때만 처리
                            if abs(value.translation.width) > abs(value.translation.height) {
                                state = value.translation.width
                            }
                        }
                        .onChanged { value in
                            // 이 카드가 움직이기 시작하면: 이 카드도, 열려있던 다른 카드도 전부 닫힌 상태로 리셋한다.
                            // "누가 열렸는지"는 onEnded에서 새로 결정한다.
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            if committedOffset != 0 {
                                withAnimation(.easeInOut(duration: 0.2)) { committedOffset = 0 }
                            }
                            if revealedID != nil {
                                revealedID = nil
                            }
                        }
                        .onEnded { value in
                            hasTriggeredAction = false

                            // Y축 이동이 더 크면 드래그 취소 (세로 스크롤 보호)
                            guard abs(value.translation.width) > abs(value.translation.height) else {
                                withAnimation(.easeOut(duration: 0.2)) { committedOffset = 0 }
                                return
                            }

                            let target = committedOffset + value.translation.width
                            withAnimation(.easeOut(duration: 0.2)) {
                                if target < -actionWidth / 2 {
                                    committedOffset = -actionWidth
                                } else if onEdit != nil, target > actionWidth / 2 {
                                    committedOffset = actionWidth
                                } else {
                                    committedOffset = 0
                                }
                            }
                            revealedID = committedOffset == 0 ? nil : id
                        }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous))
        .onChange(of: revealedID) { _, newValue in
            // 다른 카드가 열리면 이 카드는 닫는다
            if newValue != id, committedOffset != 0 {
                withAnimation(.easeInOut(duration: 0.2)) { committedOffset = 0 }
            }
        }
    }

    // 액션 공통 처리 함수
    private func handleAction(_ action: @escaping () -> Void) {
        guard !hasTriggeredAction else { return }
        hasTriggeredAction = true

        withAnimation(.easeInOut(duration: 0.2)) {
            committedOffset = 0
        }
        revealedID = nil

        // 애니메이션 약간 후 동작 실행 및 플래그 리셋
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
            hasTriggeredAction = false
        }
    }
}
