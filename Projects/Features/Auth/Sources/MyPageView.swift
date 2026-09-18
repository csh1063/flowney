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
    let onAddItemRequested: (AddItemFromShareRequest, _ onAdded: @escaping () -> Void) -> Void

    @State private var isAccountInfoPresented = false
    @State private var shareInboxStore: StoreOf<ShareInboxFeature>?
    @State private var isAppearanceSheetPresented = false
    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    public init(
        store: StoreOf<AuthFeature>,
        currentTripID: Trip.ID? = nil,
        isSubpagePresented: Binding<Bool> = .constant(false),
        autoOpenShareInbox: Binding<Bool> = .constant(false),
        onAddItemRequested: @escaping (AddItemFromShareRequest, _ onAdded: @escaping () -> Void) -> Void = { _, _ in }
    ) {
        self.store = store
        self.currentTripID = currentTripID
        self._isSubpagePresented = isSubpagePresented
        self._autoOpenShareInbox = autoOpenShareInbox
        self.onAddItemRequested = onAddItemRequested
    }

    public var body: some View {
        List {
            Section {
                Button {
                    isAccountInfoPresented = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
                            Text(providerDisplayName)
                                .font(FlowneyFont.sectionHeader)
                                .foregroundStyle(FlowneyTheme.textPrimary)
                            Text("Flowney 계정")
                                .font(FlowneyFont.caption)
                                .foregroundStyle(FlowneyTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                    }
                    .flowneyCard()
                }
                .buttonStyle(.plain)
                .flowneyCardListRow()
            }

            Section("일정") {
                Button {
                    openShareInbox()
                } label: {
                    HStack {
                        Text("공유 링크함")
                            .font(FlowneyFont.body)
                            .foregroundStyle(FlowneyTheme.textPrimary)
                        if unusedShareCount > 0 {
                            Text("\(unusedShareCount)")
                                .font(FlowneyFont.captionEmphasis)
                                .foregroundStyle(FlowneyTheme.accentLabel)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FlowneyTheme.accent, in: Capsule())
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                    }
                    .flowneyCard()
                }
                .buttonStyle(.plain)
                .flowneyCardListRow()
            }

            Section("화면") {
                Button {
                    isAppearanceSheetPresented = true
                } label: {
                    HStack {
                        Text("화면 모드")
                            .font(FlowneyFont.body)
                            .foregroundStyle(FlowneyTheme.textPrimary)
                        Spacer()
                        Text(currentAppearanceMode.displayName)
                            .font(FlowneyFont.body)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                    }
                    .flowneyCard()
                }
                .buttonStyle(.plain)
                .flowneyCardListRow()
            }

            Section("약관 및 정책") {
                VStack(spacing: FlowneySpacing.md) {
                    ForEach(Array(MyPageMenuItem.placeholderItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider()
                        }
                        HStack {
                            Text(item.title)
                                .font(FlowneyFont.body)
                                .foregroundStyle(FlowneyTheme.textPrimary)
                            Spacer()
                            Text("준비중")
                                .font(FlowneyFont.caption)
                                .foregroundStyle(FlowneyTheme.textSecondary)
                        }
                    }
                }
                .flowneyCard()
                .flowneyCardListRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(FlowneyTheme.background)
        .flowneyLeadingTitle("마이페이지")
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
                ShareInboxView(store: shareInboxStore, onAddItemRequested: onAddItemRequested)
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
                .presentationBackground(FlowneyTheme.surface)
        }
//        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 20) }
        .flowneyLifecycleLog(category: .auth)
    }

    private var appearanceSheet: some View {
        VStack(spacing: 0) {
            Text("화면 모드")
                .font(FlowneyFont.sectionHeader)
                .foregroundStyle(FlowneyTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FlowneySpacing.lg)
                .padding(.top, FlowneySpacing.md)
                .padding(.bottom, FlowneySpacing.sm)

            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Button {
                    appearanceModeRaw = mode.rawValue
                    isAppearanceSheetPresented = false
                } label: {
                    HStack {
                        Text(mode.displayName)
                            .font(FlowneyFont.body)
                            .foregroundStyle(FlowneyTheme.textPrimary)
                        Spacer()
                        if currentAppearanceMode == mode {
                            Image(systemName: "checkmark")
                                .foregroundStyle(FlowneyTheme.accent)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, FlowneySpacing.lg)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if mode != AppearanceMode.allCases.last {
                    Divider().padding(.leading, FlowneySpacing.lg)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(FlowneyTheme.surface)
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
