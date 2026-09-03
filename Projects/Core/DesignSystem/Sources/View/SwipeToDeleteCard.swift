import SwiftUI

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
