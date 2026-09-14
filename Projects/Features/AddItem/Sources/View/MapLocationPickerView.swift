import APIClient
import CoreLocation
import DesignSystem
import MapKit
import Models
import SwiftUI

struct MapLocationPickerView: View {
    let onConfirm: (ResolvedPlace) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pickedCoordinate: CLLocationCoordinate2D?
    @State private var pickedName: String?
    @State private var pickedAddress: String?
    @State private var cameraPosition: MapCameraPosition
    @State private var currentRegion: MKCoordinateRegion
    @State private var isResolving = false
    @State private var searchText = ""
    @StateObject private var searchCompleter = LocalSearchCompleterModel()
    @FocusState private var isSearchFocused: Bool
    @State private var measuredRowHeight: CGFloat = 47

    init(initialCoordinate: CLLocationCoordinate2D?, onConfirm: @escaping (ResolvedPlace) -> Void) {
        self.onConfirm = onConfirm
        let start = initialCoordinate ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        let region = MKCoordinateRegion(center: start, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        _pickedCoordinate = State(initialValue: initialCoordinate)
        _cameraPosition = State(initialValue: .region(region))
        _currentRegion = State(initialValue: region)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        if let pickedCoordinate {
                            Marker(pickedName ?? "선택한 위치", coordinate: pickedCoordinate)
                        }
                    }
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            guard let coordinate = proxy.convert(value.location, from: .local) else { return }
                            pickedCoordinate = coordinate
                            pickedName = nil
                            pickedAddress = nil
                            isSearchFocused = false
                            searchCompleter.results = []
                        }
                    )
                    .onMapCameraChange(frequency: .onEnd) { context in
                        currentRegion = context.region
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 0) {
                    searchField
                    if !searchCompleter.results.isEmpty {
                        suggestionsList
                    }
                    Spacer()
                }
            }
            .navigationTitle("위치 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isResolving {
                        ProgressView()
                    } else {
                        Button("확인") { confirm() }
                            .disabled(pickedCoordinate == nil)
                    }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: FlowneySpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FlowneyTheme.textSecondary)
            TextField("장소 검색", text: $searchText)
                .focused($isSearchFocused)
                .onChange(of: searchText) { _, newValue in
                    searchCompleter.updateQuery(newValue, region: currentRegion)
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchCompleter.results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FlowneyTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FlowneySpacing.sm)
        .padding(.vertical, FlowneySpacing.sm + 2)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous))
        .padding(FlowneySpacing.md)
    }

    private static let suggestionVisibleRowCount: CGFloat = 5.5

    private var suggestionsList: some View {
        List(searchCompleter.results, id: \.self) { result in
            Button {
                selectSuggestion(result)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(FlowneyFont.bodyEmphasis)
                        .foregroundStyle(FlowneyTheme.textPrimary)
                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(FlowneyFont.caption)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                    }
                }
                .padding(.vertical, 12)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: SuggestionRowHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: FlowneySpacing.md, bottom: 0, trailing: FlowneySpacing.md))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .onPreferenceChange(SuggestionRowHeightPreferenceKey.self) { measuredRowHeight = $0 }
        .frame(height: min(CGFloat(searchCompleter.results.count), Self.suggestionVisibleRowCount) * measuredRowHeight)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous))
        .padding(.horizontal, FlowneySpacing.md)
    }

    private func selectSuggestion(_ completion: MKLocalSearchCompletion) {
        isSearchFocused = false
        searchText = completion.title
        let request = MKLocalSearch.Request(completion: completion)
        Task {
            let search = MKLocalSearch(request: request)
            guard let response = try? await search.start(), let item = response.mapItems.first else {
                searchCompleter.results = []
                return
            }
            pickedCoordinate = item.placemark.coordinate
            pickedName = item.name ?? completion.title
            pickedAddress = Self.formattedAddress(item.placemark)
            searchCompleter.results = []
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(center: item.placemark.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                )
            }
        }
    }

    private func confirm() {
        guard let coordinate = pickedCoordinate else { return }
        if let pickedName {
            onConfirm(
                ResolvedPlace(name: pickedName, lat: coordinate.latitude, lng: coordinate.longitude, address: pickedAddress, placeId: nil)
            )
            return
        }
        isResolving = true
        Task {
            let place = await Self.resolvedPlace(for: coordinate)
            isResolving = false
            onConfirm(place)
        }
    }

    private static func resolvedPlace(for coordinate: CLLocationCoordinate2D) async -> ResolvedPlace {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        let placemark = placemarks?.first
        return ResolvedPlace(
            name: placemark?.name ?? "선택한 위치",
            lat: coordinate.latitude,
            lng: coordinate.longitude,
            address: placemark.flatMap(formattedAddress),
            placeId: nil
        )
    }

    private static func formattedAddress(_ placemark: CLPlacemark) -> String? {
        let address = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea, placemark.country]
            .compactMap { $0 }
            .joined(separator: ", ")
        return address.isEmpty ? nil : address
    }
}

@MainActor
private final class LocalSearchCompleterModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    func updateQuery(_ query: String, region: MKCoordinateRegion) {
        completer.region = region
        completer.queryFragment = query
        if query.isEmpty { results = [] }
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.results = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        FlowneyLog.error("MKLocalSearchCompleter 실패: \(error)", category: .addItem)
    }
}

private struct SuggestionRowHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 47
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
