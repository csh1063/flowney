import SwiftUI

public struct WaypinDateRangeCalendarView: View {
    @Binding private var startDate: Date
    @Binding private var endDate: Date
    @State private var displayedMonth: Date
    @State private var selectionPhase: SelectionPhase = .selectingStart

    private static let calendar = Calendar(identifier: .gregorian)
    private static let weekdayHeaderLabels = ["일", "월", "화", "수", "목", "금", "토"]

    private enum SelectionPhase {
        case selectingStart
        case selectingEnd
    }

    private enum Cell: Identifiable {
        case blank(Int)
        case day(Date)

        var id: String {
            switch self {
            case let .blank(index): return "blank-\(index)"
            case let .day(date): return "day-\(date.timeIntervalSince1970)"
            }
        }
    }

    public init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate
        self._displayedMonth = State(initialValue: Self.calendar.startOfDay(for: startDate.wrappedValue))
    }

    public var body: some View {
        VStack(spacing: WaypinSpacing.sm) {
            monthHeaderRow
            weekdayHeaderRow
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                weekRow(week)
            }
        }
    }

    private var monthHeaderRow: some View {
        HStack {
            Button {
                navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitle)
                .font(WaypinFont.bodyEmphasis)
            Spacer()
            Button {
                navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(WaypinTheme.textPrimary)
        .padding(.horizontal, WaypinSpacing.xs)
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

    private func weekRow(_ week: [Cell]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { cell in
                cellView(cell)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthTitle: String {
        let comps = Self.calendar.dateComponents([.year, .month], from: displayedMonth)
        return "\(comps.year ?? 0)년 \(comps.month ?? 0)월"
    }

    private func navigateMonth(by delta: Int) {
        guard let newMonth = Self.calendar.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        displayedMonth = newMonth
    }

    private var firstOfDisplayedMonth: Date {
        let comps = Self.calendar.dateComponents([.year, .month], from: displayedMonth)
        return Self.calendar.date(from: comps) ?? displayedMonth
    }

    private var daysInDisplayedMonth: [Date] {
        let first = firstOfDisplayedMonth
        guard let range = Self.calendar.range(of: .day, in: .month, for: first) else { return [] }
        return range.compactMap { Self.calendar.date(byAdding: .day, value: $0 - 1, to: first) }
    }

    private var cells: [Cell] {
        guard !daysInDisplayedMonth.isEmpty else { return [] }
        let firstWeekday = Self.calendar.component(.weekday, from: firstOfDisplayedMonth)
        let leadingBlanks = firstWeekday - 1
        return (0..<leadingBlanks).map { .blank($0) } + daysInDisplayedMonth.map { .day($0) }
    }

    private var weeks: [[Cell]] {
        let all = cells
        guard !all.isEmpty else { return [] }
        var rows = stride(from: 0, to: all.count, by: 7).map { Array(all[$0..<min($0 + 7, all.count)]) }
        if let lastIndex = rows.indices.last, rows[lastIndex].count < 7 {
            let missing = 7 - rows[lastIndex].count
            rows[lastIndex] += (0..<missing).map { .blank(1000 + $0) }
        }
        return rows
    }

    private func handleTap(on day: Date) {
        switch selectionPhase {
        case .selectingStart:
            startDate = day
            endDate = day
            selectionPhase = .selectingEnd

        case .selectingEnd:
            if Self.calendar.compare(day, to: startDate, toGranularity: .day) == .orderedAscending {
                startDate = day
                endDate = day
            } else {
                endDate = day
                selectionPhase = .selectingStart
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: Cell) -> some View {
        switch cell {
        case .blank:
            Color.clear
                .frame(height: 40)

        case let .day(day):
            let start = Self.calendar.startOfDay(for: startDate)
            let end = Self.calendar.startOfDay(for: endDate)
            let normalizedDay = Self.calendar.startOfDay(for: day)
            let isStart = normalizedDay == start
            let isEnd = normalizedDay == end
            let isInRange = normalizedDay > start && normalizedDay < end

            Button {
                handleTap(on: day)
            } label: {
                ZStack {
                    if isStart || isEnd || isInRange {
                        Rectangle().fill(WaypinTheme.accent.opacity(0.15))
                    }
                    if isStart || isEnd {
                        Circle()
                            .fill(WaypinTheme.accent)
                            .frame(width: 40, height: 40)
                    }
                    Text("\(Self.calendar.component(.day, from: day))")
                        .font(WaypinFont.bodyEmphasis)
                        .foregroundStyle((isStart || isEnd) ? WaypinTheme.accentLabel : WaypinTheme.textPrimary)
                }
                .frame(height: 40)
            }
            .buttonStyle(.plain)
        }
    }
}
