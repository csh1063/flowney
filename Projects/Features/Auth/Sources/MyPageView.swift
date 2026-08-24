import APIClient
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import Supabase

public struct MyPageView: View {
    @Bindable var store: StoreOf<AuthFeature>
    let currentTripID: Trip.ID?
    @Binding var isSubpagePresented: Bool
    @Binding var autoOpenShareInbox: Bool

    @State private var isAccountInfoPresented = false
    @State private var shareInboxStore: StoreOf<ShareInboxFeature>?

    public init(
        store: StoreOf<AuthFeature>,
        currentTripID: Trip.ID? = nil,
        isSubpagePresented: Binding<Bool> = .constant(false),
        autoOpenShareInbox: Binding<Bool> = .constant(false)
    ) {
        self.store = store
        self.currentTripID = currentTripID
        self._isSubpagePresented = isSubpagePresented
        self._autoOpenShareInbox = autoOpenShareInbox
    }

    public var body: some View {
        List {
            Section {
                Button {
                    isAccountInfoPresented = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: WaypinSpacing.xs) {
                            Text(providerDisplayName)
                                .font(WaypinFont.sectionHeader)
                                .foregroundStyle(WaypinTheme.textPrimary)
                            Text("Waypin 계정")
                                .font(WaypinFont.caption)
                                .foregroundStyle(WaypinTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(WaypinTheme.textSecondary)
                    }
                    .waypinCard()
                }
                .buttonStyle(.plain)
                .waypinCardListRow()
            }

            Section("일정") {
                Button {
                    openShareInbox()
                } label: {
                    HStack {
                        Text("공유 링크함")
                            .font(WaypinFont.body)
                            .foregroundStyle(WaypinTheme.textPrimary)
                        if unusedShareCount > 0 {
                            Text("\(unusedShareCount)")
                                .font(WaypinFont.captionEmphasis)
                                .foregroundStyle(WaypinTheme.accentLabel)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(WaypinTheme.accent, in: Capsule())
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(WaypinTheme.textSecondary)
                    }
                    .waypinCard()
                }
                .buttonStyle(.plain)
                .waypinCardListRow()
            }

            Section("약관 및 정책") {
                VStack(spacing: WaypinSpacing.md) {
                    ForEach(Array(MyPageMenuItem.placeholderItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider()
                        }
                        HStack {
                            Text(item.title)
                                .font(WaypinFont.body)
                                .foregroundStyle(WaypinTheme.textPrimary)
                            Spacer()
                            Text("준비중")
                                .font(WaypinFont.caption)
                                .foregroundStyle(WaypinTheme.textSecondary)
                        }
                    }
                }
                .waypinCard()
                .waypinCardListRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(WaypinTheme.background)
        .waypinLeadingTitle("마이페이지")
        .navigationDestination(isPresented: $isAccountInfoPresented) {
            AccountInfoView(store: store)
                .onAppear { isSubpagePresented = true }
                .onDisappear { isSubpagePresented = false }
        }
        .navigationDestination(
            isPresented: Binding(
                get: { shareInboxStore != nil },
                set: { isPresented in
                    if !isPresented { shareInboxStore = nil }
                }
            )
        ) {
            if let shareInboxStore {
                ShareInboxView(store: shareInboxStore)
                    .onAppear { isSubpagePresented = true }
                    .onDisappear { isSubpagePresented = false }
            }
        }
        .onAppear { applyAutoOpenShareInboxIfNeeded() }
        .onChange(of: autoOpenShareInbox) { _, _ in applyAutoOpenShareInboxIfNeeded() }
    }

    private func openShareInbox() {
        shareInboxStore = Store(initialState: ShareInboxFeature.State(defaultTripID: currentTripID)) {
            ShareInboxFeature()
        }
    }

    private func applyAutoOpenShareInboxIfNeeded() {
        guard autoOpenShareInbox else { return }
        openShareInbox()
        autoOpenShareInbox = false
    }

    private var providerDisplayName: String {
        switch store.session?.user.identities?.first?.provider {
        case "apple": return "Apple로 로그인"
        case "google": return "Google로 로그인"
        default: return store.session?.user.email ?? "로그인 정보 없음"
        }
    }

    private var unusedShareCount: Int {
        PendingShareStore.list().filter { !$0.hasBeenAdded }.count
    }
}

private struct MyPageMenuItem: Identifiable {
    let id: String
    let title: String

    static let placeholderItems: [MyPageMenuItem] = [
        MyPageMenuItem(id: "terms", title: "이용약관"),
        MyPageMenuItem(id: "privacy", title: "개인정보처리방침"),
        MyPageMenuItem(id: "oss", title: "오픈소스 라이선스"),
    ]
}
