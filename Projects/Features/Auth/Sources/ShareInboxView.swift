import AddItem
import APIClient
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct ShareInboxView: View {
    @Bindable var store: StoreOf<ShareInboxFeature>
    @State private var addItemFlowStore: StoreOf<AddItemFlowFeature>?

    public init(store: StoreOf<ShareInboxFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.shares.isEmpty {
                ContentUnavailableView {
                    Label("공유받은 링크가 없어요", systemImage: "link")
                } description: {
                    Text("구글맵 등에서 장소를 공유할 때 'Waypin에 추가'를 선택하면 여기에 모여요.")
                }
            } else {
                List {
                    ForEach(store.shares) { share in
                        SwipeToDeleteCard(
                            onDelete: { store.send(.deleteShare(share.id)) },
                            onTap: { store.send(.rowTapped(share)) }
                        ) {
                            ShareRowView(
                                share: share,
                                preview: store.previews[share.id],
                                isLoadingPreview: store.previews[share.id] == nil && !store.previewFailedIDs.contains(share.id)
                            )
                        }
                        .waypinCardListRow()
                        .task { store.send(.rowAppeared(share)) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(WaypinTheme.background)
        .waypinLeadingTitle("공유 링크함")
        .task { store.send(.onAppear) }
        .onChange(of: store.addItemFlowRequest) { _, request in
            guard let request else { return }
            addItemFlowStore = Store(initialState: request) { AddItemFlowFeature() }
            store.send(.addItemFlowRequestConsumed)
        }
        .sheet(
            isPresented: Binding(
                get: { addItemFlowStore != nil },
                set: { isPresented in
                    if !isPresented { addItemFlowStore = nil }
                }
            )
        ) {
            if let addItemFlowStore {
                AddItemFlowView(
                    store: addItemFlowStore,
                    onItemAdded: { _ in
                        if let shareID = store.addItemFlowRequestShareID {
                            store.send(.itemAdded(shareID))
                        }
                        self.addItemFlowStore = nil
                    },
                    onCancelled: { self.addItemFlowStore = nil }
                )
            }
        }
    }
}

private struct ShareRowView: View {
    let share: PendingShare

    let preview: LinkPreview?
    let isLoadingPreview: Bool

    var body: some View {
        HStack(spacing: 12) {
            previewImage
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if !share.hasBeenAdded {
                        Circle()
                            .fill(WaypinTheme.accent)
                            .frame(width: 8, height: 8)
                    }
                    Text(displayName)
                        .font(WaypinFont.bodyEmphasis)
                        .foregroundStyle(WaypinTheme.textPrimary)
                        .lineLimit(1)
                }
                if let locationText {
                    Text(locationText)
                        .font(WaypinFont.caption)
                        .foregroundStyle(WaypinTheme.textSecondary)
                        .lineLimit(1)
                }
                Text(savedAtText)
                    .font(WaypinFont.caption)
                    .foregroundStyle(WaypinTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(WaypinTheme.textSecondary)
        }
        .waypinCard()
        .overlay {
            if isLoadingPreview {
                RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous)
                    .fill(Color.black.opacity(0.3))
                    .overlay { ProgressView().tint(.white) }
            }
        }
    }

    @ViewBuilder
    private var previewImage: some View {
        if let imageURLString = preview?.imageURLString, let url = URL(string: imageURLString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(WaypinTheme.background)
            .overlay {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(WaypinTheme.textSecondary)
            }
    }

    private var displayName: String {
        preview?.name ?? URL(string: share.urlString)?.host ?? share.urlString
    }

    private var locationText: String? {
        switch (preview?.city, preview?.country) {
        case let (city?, country?): return "\(city), \(country)"
        case let (city?, nil): return city
        case let (nil, country?): return country
        case (nil, nil): return nil
        }
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
