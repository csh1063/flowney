import APIClient
import CoreLocation
import DesignSystem
import MapKit
import SwiftUI

struct MapLocationPickerView: View {
    let onConfirm: (ResolvedPlace) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pickedCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition
    @State private var isResolving = false

    init(initialCoordinate: CLLocationCoordinate2D?, onConfirm: @escaping (ResolvedPlace) -> Void) {
        self.onConfirm = onConfirm
        let start = initialCoordinate ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        _pickedCoordinate = State(initialValue: initialCoordinate)
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(center: start, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            )
        )
    }

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if let pickedCoordinate {
                        Marker("", coordinate: pickedCoordinate)
                    }
                }
                .gesture(
                    SpatialTapGesture().onEnded { value in
                        guard let coordinate = proxy.convert(value.location, from: .local) else { return }
                        pickedCoordinate = coordinate
                    }
                )
            }
            .ignoresSafeArea(edges: .bottom)
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

    private func confirm() {
        guard let coordinate = pickedCoordinate else { return }
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
        let address = [placemark?.thoroughfare, placemark?.locality, placemark?.administrativeArea, placemark?.country]
            .compactMap { $0 }
            .joined(separator: ", ")
        return ResolvedPlace(
            name: placemark?.name ?? "선택한 위치",
            lat: coordinate.latitude,
            lng: coordinate.longitude,
            address: address.isEmpty ? nil : address,
            placeId: nil
        )
    }
}
