import ComposableArchitecture
import DesignSystem
import SwiftUI
import Supabase

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
