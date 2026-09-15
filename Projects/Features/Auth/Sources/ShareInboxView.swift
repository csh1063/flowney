import APIClient
import ComposableArchitecture
import DesignSystem
import Models
import SafariServices
import SwiftUI

public struct ShareInboxView: View {
    @Bindable var store: StoreOf<ShareInboxFeature>
    let onAddItemRequested: (AddItemFromShareRequest, _ onAdded: @escaping () -> Void) -> Void
    @State private var revealedRowID: AnyHashable?
    @State private var linkCheckURL: URL?

    public init(
        store: StoreOf<ShareInboxFeature>,
        onAddItemRequested: @escaping (AddItemFromShareRequest, _ onAdded: @escaping () -> Void) -> Void
    ) {
        self.store = store
        self.onAddItemRequested = onAddItemRequested
    }

    public var body: some View {
        Group {
            if store.shares.isEmpty {
                ContentUnavailableView {
                    Label("공유받은 링크가 없어요", systemImage: "link")
                } description: {
                    Text("구글맵 등에서 장소를 공유할 때 'Flowney에 추가'를 선택하면 여기에 모여요.")
                }
            } else {
                List {
                    ForEach(store.shares) { share in
                        let isLoadingResolve = store.resolvedPlaces[share.id] == nil && !store.resolveFailedIDs.contains(share.id)
                        SwipeToDeleteCard(
                            id: share.id,
                            revealedID: $revealedRowID,
                            onDelete: { store.send(.deleteShare(share.id)) },
                            onTap: {
                                guard !isLoadingResolve else { return }
                                let resolvedPlace = store.resolvedPlaces[share.id]
                                let request = AddItemFromShareRequest(
                                    shareID: share.id,
                                    defaultTripID: store.defaultTripID,
                                    linkURLText: share.urlString,
                                    prefillName: resolvedPlace?.name ?? "",
                                    prefillResolvedPlace: resolvedPlace
                                )
                                onAddItemRequested(request) {
                                    store.send(.itemAdded(share.id))
                                }
                            }
                        ) {
                            ShareRowView(
                                share: share,
                                resolvedPlace: store.resolvedPlaces[share.id],
                                isLoadingResolve: isLoadingResolve,
                                onLinkCheckTapped: {
                                    linkCheckURL = URL(string: share.urlString)
                                }
                            )
                        }
                        .flowneyCardListRow()
                        .task { store.send(.rowAppeared(share)) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(FlowneyTheme.background)
        .flowneyLeadingTitle("공유 링크함")
        .task { store.send(.onAppear) }
        .sheet(
            isPresented: Binding(
                get: { linkCheckURL != nil },
                set: { isPresented in if !isPresented { linkCheckURL = nil } }
            )
        ) {
            if let linkCheckURL {
                SafariView(url: linkCheckURL).ignoresSafeArea()
            }
        }
    }
}

private struct ShareRowView: View {
    let share: PendingShare
    let resolvedPlace: ResolvedPlace?
    let isLoadingResolve: Bool
    let onLinkCheckTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            linkCheckButton

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if !share.hasBeenAdded {
                        Circle()
                            .fill(FlowneyTheme.accent)
                            .frame(width: 8, height: 8)
                    }
                    Text(displayName)
                        .font(FlowneyFont.bodyEmphasis)
                        .foregroundStyle(FlowneyTheme.textPrimary)
                        .lineLimit(1)
                }
                if let locationText {
                    Text(locationText)
                        .font(FlowneyFont.caption)
                        .foregroundStyle(FlowneyTheme.textSecondary)
                        .lineLimit(1)
                }
                Text(savedAtText)
                    .font(FlowneyFont.caption)
                    .foregroundStyle(FlowneyTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(FlowneyTheme.textSecondary)
        }
        .padding(FlowneySpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            if isLoadingResolve {
                Color.black.opacity(0.3)
                    .overlay { ProgressView().tint(.white) }
            }
        }
    }

    private var linkCheckButton: some View {
        Button(action: onLinkCheckTapped) {
            VStack(spacing: 2) {
                Image(systemName: "safari")
                    .font(.system(size: 18))
                Text("링크확인")
                    .font(FlowneyFont.caption)
            }
            .foregroundStyle(FlowneyTheme.textSecondary)
            .frame(width: 48, height: 48)
            .background(FlowneyTheme.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var displayName: String {
        resolvedPlace?.name ?? URL(string: share.urlString)?.host ?? share.urlString
    }

    private var locationText: String? {
        resolvedPlace?.address
    }

    private var savedAtText: String {
        let interval = Date().timeIntervalSince(share.savedAt)
        switch interval {
        case ..<60:
            return "방금 전"
        case ..<3600:
            return "\(Int(interval / 60))분 전"
        case ..<86400:
            return "\(Int(interval / 3600))시간 전"
        case ..<172800:
            return "하루 전"
        default:
            return Self.savedAtDateFormatter.string(from: share.savedAt)
        }
    }

    private static let savedAtDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
