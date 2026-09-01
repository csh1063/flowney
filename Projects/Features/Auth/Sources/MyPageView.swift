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
    @State private var isAppearanceSheetPresented = false
    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw: String = AppearanceMode.system.rawValue

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

            Section("화면") {
                Button {
                    isAppearanceSheetPresented = true
                } label: {
                    HStack {
                        Text("화면 모드")
                            .font(WaypinFont.body)
                            .foregroundStyle(WaypinTheme.textPrimary)
                        Spacer()
                        Text(currentAppearanceMode.displayName)
                            .font(WaypinFont.body)
                            .foregroundStyle(WaypinTheme.textSecondary)
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
        .sheet(isPresented: $isAppearanceSheetPresented) {
            appearanceSheet
                .presentationDetents([.height(232)])
                .presentationDragIndicator(.visible)
                .presentationBackground(WaypinTheme.surface)
        }
    }

    private var appearanceSheet: some View {
        VStack(spacing: 0) {
            Text("화면 모드")
                .font(WaypinFont.sectionHeader)
                .foregroundStyle(WaypinTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, WaypinSpacing.lg)
                .padding(.top, WaypinSpacing.md)
                .padding(.bottom, WaypinSpacing.sm)

            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Button {
                    appearanceModeRaw = mode.rawValue
                    isAppearanceSheetPresented = false
                } label: {
                    HStack {
                        Text(mode.displayName)
                            .font(WaypinFont.body)
                            .foregroundStyle(WaypinTheme.textPrimary)
                        Spacer()
                        if currentAppearanceMode == mode {
                            Image(systemName: "checkmark")
                                .foregroundStyle(WaypinTheme.accent)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, WaypinSpacing.lg)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if mode != AppearanceMode.allCases.last {
                    Divider().padding(.leading, WaypinSpacing.lg)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(WaypinTheme.surface)
    }

    private var currentAppearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
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
