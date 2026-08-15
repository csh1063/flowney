import APIClient
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import Supabase

/// 마이페이지 — 계정정보(탭하면 상세로) / 일정(공유 링크함) / 약관 및 정책 세 섹션.
/// 항목이 늘어나기 쉽게 `MyPageMenuItem` 배열 형태로 짜뒀다.
public struct MyPageView: View {
    @Bindable var store: StoreOf<AuthFeature>
    // 공유 링크함의 트립 피커 기본 선택값 — 지도 탭에 지금 불러와져있는 여행.
    let currentTripID: Trip.ID?
    // 이 화면에서 하위 페이지(계정정보/공유링크함)로 이동했는지를 RootView에 알려서,
    // 떠 있는 커스텀 탭바를 그동안 숨길 수 있게 한다.
    @Binding var isSubpagePresented: Bool
    // 공유 익스텐션으로 링크를 저장한 뒤 앱을 다시 켠 첫 실행이면 RootView가 이 값을 한 번
    // true로 세팅한다 — 소비하는 즉시 다시 false로 되돌린다(1회성 트리거).
    @Binding var autoOpenShareInbox: Bool

    @State private var isAccountInfoPresented = false
    // `@Presents`/`ifLet` 대신 View가 Store를 직접 소유하는 이 프로젝트의 공통 패턴
    // (project_tca_presents_crash 참고) — nil이 아니면 화면이 뜬다. `.navigationDestination`
    // 클로저 안에서 `Store(initialState:...)`를 매번 인라인으로 새로 만들면, body가
    // 재평가될 때마다(예: 아래 `isSubpagePresented` 바인딩이 바뀌어 부모가 다시 그려질 때)
    // Store가 통째로 새로 만들어지면서 방금 로드된 상태가 날아간다 — 실제로 이 버그로 공유
    // 링크함이 항상 빈 목록으로 보였다. `@State`로 한 번만 만들어서 재사용해야 한다.
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

    // 한 번도 어느 여행에도 추가된 적 없는 공유 링크 개수 — 뱃지 숫자.
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
