import Models
import SwiftUI

public struct WaypinTripDayCalendarView: View {
    private static let calendar = Calendar(identifier: .gregorian)
    private static let weekdayHeaderLabels = ["일", "월", "화", "수", "목", "금", "토"]

    private let days: [TripDay]
    private let selectedDayID: TripDay.ID?
    private let onSelectDay: (TripDay) -> Void

    public init(days: [TripDay], selectedDayID: TripDay.ID?, onSelectDay: @escaping (TripDay) -> Void) {
        self.days = days
        self.selectedDayID = selectedDayID
        self.onSelectDay = onSelectDay
    }

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

    public var body: some View {
        ScrollView {
            VStack(spacing: WaypinSpacing.md) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous)
                .fill(WaypinTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous)
                .stroke(WaypinTheme.divider, lineWidth: 1)
        )
    }

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(Self.weekdayHeaderLabels, id: \.self) { label in
                Text(label)
                    .font(WaypinFont.caption.weight(.semibold))
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
                    .foregroundStyle(WaypinTheme.accent)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, WaypinSpacing.xs)
    }

    private func weekRow(_ week: [Cell]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { cell in
                cellView(cell)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var cells: [Cell] {
        guard let first = days.first else { return [] }
        let firstWeekday = Self.calendar.component(.weekday, from: first.dayDate)
        let leadingBlanks = firstWeekday - 1
        return (0..<leadingBlanks).map { .blank($0) } + days.map { .day($0) }
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

    private func weekHasMonthLabel(_ week: [Cell]) -> Bool {
        week.contains { monthLabel(for: $0) != nil }
    }

    private func monthLabel(for cell: Cell) -> String? {
        guard case let .day(day) = cell, let index = days.firstIndex(where: { $0.id == day.id }) else { return nil }
        let isMonthStart: Bool =
            if index == 0 {
                true
            } else {
                Self.calendar.component(.month, from: days[index].dayDate)
                    != Self.calendar.component(.month, from: days[index - 1].dayDate)
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
            let isSelected = day.id == selectedDayID
            let isToday = Self.calendar.isDateInToday(day.dayDate)
            Button {
                onSelectDay(day)
            } label: {
                Text("\(Self.calendar.component(.day, from: day.dayDate))")
                    .font(WaypinFont.bodyEmphasis)
                    .foregroundStyle(isSelected ? WaypinTheme.fillLabel : WaypinTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? WaypinTheme.fill : Color.clear, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(WaypinTheme.accent, lineWidth: isToday && !isSelected ? 1.5 : 0)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}
