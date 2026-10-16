import DesignSystem
import Models
import SwiftUI

struct MemoItemRowView: View {
    let item: MemoItem
    let onToggleDone: () -> Void
    let onDueDateTapped: () -> Void
    let onDelete: () -> Void
    @Environment(\.isOfflineViewing) private var isOfflineViewing

    static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E) HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    var body: some View {
        HStack(alignment: .center, spacing: FlowneySpacing.sm) {
            if item.kind == .checklist {
                Button(action: onToggleDone) {
                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isDone ? FlowneyTheme.accent : FlowneyTheme.textSecondary)
                        .font(.system(size: 20))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(isOfflineViewing)
            } else {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(FlowneyTheme.textSecondary)
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
            }

            Text(item.text)
                .font(FlowneyFont.body)
                .strikethrough(item.kind == .checklist && item.isDone)
                .foregroundStyle(item.isDone ? FlowneyTheme.textSecondary : FlowneyTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.kind == .checklist {
                Button(action: onDueDateTapped) {
                    Text(item.dueDate.map { Self.dueDateFormatter.string(from: $0) } ?? "기한없음")
                        .font(FlowneyFont.caption)
                        .foregroundStyle(FlowneyTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(isOfflineViewing)
            }
        }
//        .padding(.vertical, FlowneySpacing.xs)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isOfflineViewing {
                Button(role: .destructive, action: onDelete) {
                    Label("삭제", systemImage: "trash")
                }
            }
        }
    }
}
