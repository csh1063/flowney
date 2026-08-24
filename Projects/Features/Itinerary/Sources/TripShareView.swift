import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

struct TripShareView: View {
    @Bindable var store: StoreOf<TripShareFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WaypinSpacing.lg) {
                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, WaypinSpacing.xxl)
                    } else {
                        sectionBlock("공개 범위") {
                            Picker("공개 범위", selection: $store.visibility) {
                                Text("전체공개").tag(TripShare.Visibility.pub)
                                Text("비공개").tag(TripShare.Visibility.password)
                            }
                            .pickerStyle(.segmented)

                            if store.visibility == .password {
                                SecureField(
                                    store.share?.visibility == .password ? "비밀번호 변경(선택)" : "비밀번호",
                                    text: $store.password
                                )
                                .padding(.top, WaypinSpacing.sm)
                            }
                        }

                        Button {
                            store.send(.generateButtonTapped)
                        } label: {
                            if store.isSaving {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(store.share == nil ? "링크 생성" : "링크 업데이트")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.waypinPrimary)
                        .disabled(store.isSaving)

                        if let share = store.share {
                            sectionBlock("공유 링크") {
                                Text(share.shareURL.absoluteString)
                                    .font(WaypinFont.caption)
                                    .foregroundStyle(WaypinTheme.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                HStack(spacing: WaypinSpacing.sm) {
                                    Button {
                                        store.send(.copyLinkButtonTapped)
                                    } label: {
                                        Label(store.didCopyLink ? "복사됨" : "복사", systemImage: "doc.on.doc")
                                    }
                                    .buttonStyle(.bordered)

                                    ShareLink(item: share.shareURL) {
                                        Label("공유", systemImage: "square.and.arrow.up")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.top, WaypinSpacing.xs)
                            }

                            Button(role: .destructive) {
                                store.send(.revokeButtonTapped)
                            } label: {
                                Text("공유 중지")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(store.isSaving)
                        }

                        if let errorMessage = store.errorMessage {
                            Text(errorMessage)
                                .font(WaypinFont.caption)
                                .foregroundStyle(WaypinTheme.error)
                                .waypinCard()
                        }
                    }
                }
                .padding(WaypinSpacing.lg)
            }
            .background(WaypinTheme.background)
            .navigationTitle("여행 공유")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    private func sectionBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: WaypinSpacing.sm) {
            Text(title)
                .font(WaypinFont.sectionHeader)
                .foregroundStyle(WaypinTheme.textSecondary)
            content()
        }
        .waypinCard()
    }
}
