import ComposableArchitecture
import DesignSystem
import SwiftUI
import Supabase

/// 마이페이지 "계정정보" 카드를 눌러서 들어오는 상세 화면. 지금은 이메일뿐이지만, 나중에
/// 계정 관련 항목이 늘어날 자리라 별도 화면으로 뺐다.
public struct AccountInfoView: View {
    @Bindable var store: StoreOf<AuthFeature>

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section {
                HStack {
                    Text("이메일")
                        .font(WaypinFont.body)
                        .foregroundStyle(WaypinTheme.textPrimary)
                    Spacer()
                    Text(store.session?.user.email ?? "-")
                        .font(WaypinFont.body)
                        .foregroundStyle(WaypinTheme.textSecondary)
                }
                .waypinCard()
                .waypinCardListRow()
            }

            Section {
                Button(role: .destructive) {
                    store.send(.signOutTapped)
                } label: {
                    HStack {
                        Text("로그아웃")
                            .font(WaypinFont.bodyEmphasis)
                            .foregroundStyle(WaypinTheme.error)
                        Spacer()
                        if store.isLoading {
                            ProgressView()
                        }
                    }
                    .waypinCard()
                }
                .buttonStyle(.plain)
                .disabled(store.isLoading)
                .waypinCardListRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(WaypinTheme.background)
        .waypinLeadingTitle("회원정보")
    }
}
