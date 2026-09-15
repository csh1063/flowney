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
                        .font(FlowneyFont.body)
                        .foregroundStyle(FlowneyTheme.textPrimary)
                    Spacer()
                    Text(store.session?.user.email ?? "-")
                        .font(FlowneyFont.body)
                        .foregroundStyle(FlowneyTheme.textSecondary)
                }
                .flowneyCard()
                .flowneyCardListRow()
            }

            Section {
                Button(role: .destructive) {
                    store.send(.signOutTapped)
                } label: {
                    HStack {
                        Text("로그아웃")
                            .font(FlowneyFont.bodyEmphasis)
                            .foregroundStyle(FlowneyTheme.error)
                        Spacer()
                        if store.isLoading {
                            ProgressView()
                        }
                    }
                    .flowneyCard()
                }
                .buttonStyle(.plain)
                .disabled(store.isLoading)
                .flowneyCardListRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(FlowneyTheme.background)
        .flowneyLeadingTitle("회원정보")
    }
}
