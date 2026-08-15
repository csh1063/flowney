import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

/// 일정 추가 마법사 2단계 — 여행 기간을 실제 요일에 맞춰 배치한 달력 그리드. 여행 범위
/// 밖의 칸은 숫자 없이 빈 칸으로만 채운다(선택 불가). 7일이 넘으면 자연스럽게 여러 줄로
/// 이어지고, 월이 바뀌는 줄 위에는 그 줄에 걸친 월 이름을 표시한다.
struct DaySelectionCalendarView: View {
    @Bindable var store: StoreOf<AddItemFlowFeature>

    private static let calendar = Calendar(identifier: .gregorian)
    private static let weekdayHeaderLabels = ["일", "월", "화", "수", "목", "금", "토"]

    private enum Cell: Identifiable {
        case blank(Int)
        case day(TripDay)

        var id: String {
            switch self {
            case let .blank(index): return "blank-\(index)"
            case let .day(day): return day.id.uuidString
            }
        }
    }

    var body: some View {
        Group {
            if store.isLoadingDays && store.days.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.days.isEmpty {
                ContentUnavailableView("날짜 정보를 찾을 수 없어요", systemImage: "calendar")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: WaypinSpacing.sm) {
                        weekdayHeaderRow

                        ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                            if weekHasMonthLabel(week) {
                                monthLabelRow(week)
                            }
                            weekRow(week)
                        }
                    }
                    .padding(WaypinSpacing.lg)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(WaypinTheme.background)
    }

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(Self.weekdayHeaderLabels, id: \.self) { label in
                Text(label)
                    .font(WaypinFont.caption)
                    .foregroundStyle(WaypinTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func monthLabelRow(_ week: [Cell]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { cell in
                Text(monthLabel(for: cell) ?? "")
                    .font(WaypinFont.captionEmphasis)
                    .foregroundStyle(WaypinTheme.textPrimary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekRow(_ week: [Cell]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { cell in
                cellView(cell)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // 여행 시작일의 실제 요일부터 시작하도록, 그 요일 앞자리만큼 빈 칸을 채운다. 뒷쪽은
    // `weeks`가 7개 단위로 나누면서 자연히 짧은 마지막 줄로 끝나 별도 처리가 필요 없다.
    private var cells: [Cell] {
        guard let first = store.days.first else { return [] }
        let firstWeekday = Self.calendar.component(.weekday, from: first.dayDate)  // 일=1...토=7
        let leadingBlanks = firstWeekday - 1
        return (0..<leadingBlanks).map { .blank($0) } + store.days.map { .day($0) }
    }

    private var weeks: [[Cell]] {
        let all = cells
        guard !all.isEmpty else { return [] }
        var rows = stride(from: 0, to: all.count, by: 7).map { Array(all[$0..<min($0 + 7, all.count)]) }
        // 마지막 줄이 7칸을 못 채우면 나머지 칸도 빈 칸으로 채워야, 각 열의 너비가
        // 다른 줄과 똑같이 맞는다(안 채우면 적은 개수로 HStack이 넓게 나눠 칸이 커 보임).
        if let lastIndex = rows.indices.last, rows[lastIndex].count < 7 {
            let missing = 7 - rows[lastIndex].count
            rows[lastIndex] += (0..<missing).map { .blank(1000 + $0) }
        }
        return rows
    }

    private func weekHasMonthLabel(_ week: [Cell]) -> Bool {
        week.contains { monthLabel(for: $0) != nil }
    }

    // 여행의 첫날이거나, 바로 앞날과 월이 다르면 그 날짜의 월을 표시한다.
    private func monthLabel(for cell: Cell) -> String? {
        guard case let .day(day) = cell, let index = store.days.firstIndex(where: { $0.id == day.id }) else { return nil }
        let isMonthStart: Bool =
            if index == 0 {
                true
            } else {
                Self.calendar.component(.month, from: store.days[index].dayDate)
                    != Self.calendar.component(.month, from: store.days[index - 1].dayDate)
            }
        guard isMonthStart else { return nil }
        return "\(Self.calendar.component(.month, from: day.dayDate))월"
    }

    @ViewBuilder
    private func cellView(_ cell: Cell) -> some View {
        switch cell {
        case .blank:
            Color.clear
                .frame(height: 40)
        case let .day(day):
            let isSelected = day.id == store.selectedDay?.id
            Button {
                store.send(.dayCellTapped(day))
            } label: {
                Text("\(Self.calendar.component(.day, from: day.dayDate))")
                    .font(WaypinFont.bodyEmphasis)
                    .foregroundStyle(isSelected ? WaypinTheme.accentLabel : WaypinTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? WaypinTheme.accent : WaypinTheme.surface, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }
}
