import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

struct DaySelectionCalendarView: View {
    @Bindable var store: StoreOf<AddItemFlowFeature>

    var body: some View {
        Group {
            if store.isLoadingDays && store.days.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.days.isEmpty {
                ContentUnavailableView("날짜 정보를 찾을 수 없어요", systemImage: "calendar")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                WaypinTripDayCalendarView(
                    days: Array(store.days),
                    selectedDayID: store.selectedDay?.id
                ) { day in
                    store.send(.dayCellTapped(day))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(WaypinTheme.background)
    }
}
