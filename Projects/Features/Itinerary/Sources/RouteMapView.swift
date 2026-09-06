import ComposableArchitecture
import CoreLocation
import DesignSystem
import GoogleMaps
import Models
import SwiftUI
import UIKit

struct RouteMapView: UIViewRepresentable {
    let items: IdentifiedArrayOf<ItineraryItem>
    let legs: IdentifiedArrayOf<RouteLeg>
    let countries: IdentifiedArrayOf<TripCountry>
    let currentStopIndex: Int?
    let animateTrigger: Int
    let jumpTrigger: Int
    let focusedItemID: ItineraryItem.ID?
    let onAnimationCompleted: () -> Void
    let onMarkerTapped: (ItineraryItem.ID) -> Void
    var bottomInset: CGFloat = 0

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(withLatitude: 37.5665, longitude: 126.9780, zoom: 12)
        options.backgroundColor = WaypinTheme.backgroundUIColor
        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        context.coordinator.onMarkerTapped = onMarkerTapped
        context.coordinator.engine = TravelerAnimationEngine(mapView: mapView)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.onMarkerTapped = onMarkerTapped
        context.coordinator.applyMapStyle(colorScheme: context.environment.colorScheme)
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        context.coordinator.update(
            items: items,
            legs: legs,
            countries: countries,
            currentStopIndex: currentStopIndex,
            animateTrigger: animateTrigger,
            jumpTrigger: jumpTrigger,
            focusedItemID: focusedItemID,
            onAnimationCompleted: onAnimationCompleted
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency GMSMapViewDelegate {
        var mapView: GMSMapView?
        var engine: TravelerAnimationEngine?
        var onMarkerTapped: ((ItineraryItem.ID) -> Void)?

        private var lastAppliedColorScheme: ColorScheme?

        func applyMapStyle(colorScheme: ColorScheme) {
            guard colorScheme != lastAppliedColorScheme else { return }
            lastAppliedColorScheme = colorScheme
            mapView?.mapStyle = colorScheme == .dark ? try? GMSMapStyle(jsonString: Self.darkMapStyleJSON) : nil
        }

        private static let darkMapStyleJSON = """
        [
          {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
          {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
          {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
          {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
          {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#4b6878"}]},
          {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#a2b6c3"}]},
          {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
          {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
          {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
          {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
          {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6b9a76"}]},
          {"featureType": "poi.park", "elementType": "labels.text.stroke", "stylers": [{"color": "#1c2a2c"}]},
          {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
          {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
          {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
          {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
          {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
          {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
          {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f3d19c"}]},
          {"featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{"color": "#8a6f52"}]},
          {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#7d8792"}]},
          {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
          {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
          {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
          {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]},
          {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#17263c"}]}
        ]
        """

        private var drawnKey = ""
        private var lastAnimateTrigger: Int?
        private var lastJumpTrigger: Int?
        private var markers: [GMSMarker] = []
        private var transferMarkers: [GMSMarker] = []
        private var alternativePolylines: [GMSPolyline] = []

        private struct LegPolylineSegment {
            let polyline: GMSPolyline
            let path: GMSPath
            let length: Double
            let travelColor: UIColor
            let travelWidth: CGFloat
            let mutedColor: UIColor
        }
        private struct LegPolylineGroup {
            var segments: [LegPolylineSegment]
            var totalLength: Double
        }
        private var legPolylineGroups: [String: LegPolylineGroup] = [:]
        private var highlightedLegID: String?
        private var mutedPolylines: [(polyline: GMSPolyline, path: GMSPath, color: UIColor)] = []

        func update(
            items: IdentifiedArrayOf<ItineraryItem>,
            legs: IdentifiedArrayOf<RouteLeg>,
            countries: IdentifiedArrayOf<TripCountry>,
            currentStopIndex: Int?,
            animateTrigger: Int,
            jumpTrigger: Int,
            focusedItemID: ItineraryItem.ID?,
            onAnimationCompleted: @escaping () -> Void
        ) {
            guard let mapView else { return }

            let itemsKey = items.map { "\($0.id.uuidString):\($0.countryCode ?? "")" }.joined(separator: ",")
            let legsKey = legs.map(\.id).joined(separator: ",")
            let countriesKey = countries.map { "\($0.countryCode):\($0.color)" }.joined(separator: ",")
            let key = itemsKey + "|" + legsKey + "|" + countriesKey
            if key != drawnKey {
                drawnKey = key
                redraw(items: items, legs: legs, countries: countries, mapView: mapView)
            }

            updateMarkerStyles(currentStopIndex: currentStopIndex, items: items)

            let isFirstUpdate = lastAnimateTrigger == nil && lastJumpTrigger == nil
            let shouldAnimate = !isFirstUpdate && lastAnimateTrigger != animateTrigger
            let shouldJump = !isFirstUpdate && lastJumpTrigger != jumpTrigger
            lastAnimateTrigger = animateTrigger
            lastJumpTrigger = jumpTrigger

            if shouldAnimate {
                animateCurrentLeg(items: items, legs: legs, currentStopIndex: currentStopIndex, onAnimationCompleted: onAnimationCompleted)
            } else if shouldJump {
                if let highlightedLegID {
                    unstyleLeg(highlightedLegID)
                    self.highlightedLegID = nil
                }
                jump(to: focusedItemID, items: items, mapView: mapView)
            }
        }

        private func updateMarkerStyles(currentStopIndex: Int?, items: IdentifiedArrayOf<ItineraryItem>) {
            for (index, marker) in markers.enumerated() {
                let itemType = items.indices.contains(index) ? items[index].itemType : nil
                guard let currentStopIndex else {
                    marker.opacity = 1
                    if let itemType { marker.icon = Self.markerImage(for: itemType) }
                    continue
                }
                if index < currentStopIndex {
                    marker.opacity = 0.45
                    if let itemType { marker.icon = Self.markerImage(for: itemType) }
                } else if index == currentStopIndex {
                    marker.opacity = 1
                    if let itemType { marker.icon = Self.markerImage(for: itemType, isCurrent: true) }
                } else {
                    marker.opacity = 1
                    if let itemType { marker.icon = Self.markerImage(for: itemType) }
                }
            }
        }

        private static func pinColor(for itemType: ItemType) -> UIColor {
            switch itemType {
            case .airport: return UIColor(hex: "#4A6FA5")
            case .sight: return UIColor(hex: "#2F8F5B")
            case .meal: return UIColor(hex: "#F5A623")
            case .lodge: return WaypinTheme.brandGoldUIColor
            case .transport: return UIColor(hex: "#0072CE")
            case .activity: return UIColor(hex: "#8E44AD")
            case .shopping: return UIColor(hex: "#E85D9A")
            case .freeTime: return UIColor(hex: "#20B2AA")
            case .other: return .systemGray
            }
        }

        private static func markerImage(for itemType: ItemType, isCurrent: Bool = false) -> UIImage {
            let diameter: CGFloat = isCurrent ? 40 : 32
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
            return renderer.image { _ in
                let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter).insetBy(dx: 2, dy: 2)
                let path = UIBezierPath(ovalIn: rect)
                pinColor(for: itemType).setFill()
                path.fill()

                path.lineWidth = isCurrent ? 3 : 2
                (isCurrent ? UIColor.systemBlue : UIColor.white).setStroke()
                path.stroke()

                let emoji = itemType.icon as NSString
                let font = UIFont.systemFont(ofSize: isCurrent ? 18 : 15)
                let textSize = emoji.size(withAttributes: [.font: font])
                let textRect = CGRect(
                    x: (diameter - textSize.width) / 2,
                    y: (diameter - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                emoji.draw(in: textRect, withAttributes: [.font: font])
            }
        }

        private func animateCurrentLeg(
            items: IdentifiedArrayOf<ItineraryItem>,
            legs: IdentifiedArrayOf<RouteLeg>,
            currentStopIndex: Int?,
            onAnimationCompleted: @escaping () -> Void
        ) {
            guard
                let currentStopIndex, currentStopIndex > 0,
                items.indices.contains(currentStopIndex),
                items.indices.contains(currentStopIndex - 1)
            else {
                onAnimationCompleted()
                return
            }

            let fromItem = items[currentStopIndex - 1]
            let toItem = items[currentStopIndex]

            guard
                let fromLat = fromItem.lat, let fromLng = fromItem.lng,
                let toLat = toItem.lat, let toLng = toItem.lng
            else {
                onAnimationCompleted()
                return
            }

            let leg = legs[id: "\(fromItem.id)-\(toItem.id)"] ?? RouteLeg(
                fromItemId: fromItem.id,
                toItemId: toItem.id,
                mode: toItem.arrivalMode ?? .walk,
                status: .skipped
            )
            let legKey = leg.id

            if let highlightedLegID, highlightedLegID != legKey {
                unstyleLeg(highlightedLegID)
            }
            highlightedLegID = legKey

            engine?.animate(
                leg: leg,
                from: CLLocationCoordinate2D(latitude: fromLat, longitude: fromLng),
                to: CLLocationCoordinate2D(latitude: toLat, longitude: toLng),
                onProgress: { [weak self] fraction in
                    self?.styleLeg(legKey, fraction: fraction)
                },
                onCompleted: onAnimationCompleted
            )
        }

        private func jump(to focusedItemID: ItineraryItem.ID?, items: IdentifiedArrayOf<ItineraryItem>, mapView: GMSMapView) {
            guard let focusedItemID, let item = items[id: focusedItemID], let lat = item.lat, let lng = item.lng else {
                fitAll(items: items, mapView: mapView)
                return
            }
            let target = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let camera = GMSCameraPosition.camera(withTarget: target, zoom: 15)
            mapView.animate(to: camera)
        }

        private func fitAll(items: IdentifiedArrayOf<ItineraryItem>, mapView: GMSMapView) {
            var bounds = GMSCoordinateBounds()
            var hasAny = false
            for item in items {
                guard let lat = item.lat, let lng = item.lng else { continue }
                bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                hasAny = true
            }
            guard hasAny else { return }
            let edgeInsets = UIEdgeInsets(top: 64, left: 64, bottom: 64, right: 64)
            mapView.animate(with: GMSCameraUpdate.fit(bounds, with: edgeInsets))
        }

        private func redraw(
            items: IdentifiedArrayOf<ItineraryItem>,
            legs: IdentifiedArrayOf<RouteLeg>,
            countries: IdentifiedArrayOf<TripCountry>,
            mapView: GMSMapView
        ) {
            let countryColors = Dictionary(uniqueKeysWithValues: countries.map { ($0.countryCode, UIColor(hex: $0.color)) })
            markers.forEach { $0.map = nil }
            legPolylineGroups.values.forEach { group in group.segments.forEach { $0.polyline.map = nil } }
            alternativePolylines.forEach { $0.map = nil }
            transferMarkers.forEach { $0.map = nil }
            markers = []
            legPolylineGroups = [:]
            alternativePolylines = []
            transferMarkers = []
            mutedPolylines = []
            highlightedLegID = nil

            for (index, item) in items.enumerated() {
                guard let lat = item.lat, let lng = item.lng, lat.isFinite, lng.isFinite else { continue }
                let position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let marker = GMSMarker(position: position)
                marker.title = "\(index + 1). \(item.name)"
                marker.userData = item.id
                marker.icon = Self.markerImage(for: item.itemType)
                marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                marker.map = mapView
                markers.append(marker)
            }

            for index in 0 ..< max(items.count - 1, 0) {
                let fromItem = items[index]
                let toItem = items[index + 1]
                guard
                    let fLat = fromItem.lat, let fLng = fromItem.lng,
                    let tLat = toItem.lat, let tLng = toItem.lng,
                    fLat.isFinite, fLng.isFinite, tLat.isFinite, tLng.isFinite
                else { continue }

                let leg = legs[id: "\(fromItem.id)-\(toItem.id)"]
                let legKey = leg?.id ?? "\(fromItem.id)-\(toItem.id)"
                let hasRealRoute = leg?.status == .ok
                let mutedColor = fromItem.countryCode.flatMap { countryColors[$0] } ?? WaypinTheme.brandNavyUIColor

                let segments: [LegPolylineSegment]
                if let leg, RoutePathDecoding.usesSteppedRendering(leg: leg, hasRealRoute: hasRealRoute) {
                    segments = drawSteppedPolylines(for: leg, mutedColor: mutedColor, mapView: mapView)
                } else {
                    let decodedPoints = RoutePathDecoding.singlePolylinePoints(
                        leg: leg,
                        hasRealRoute: hasRealRoute,
                        from: CLLocationCoordinate2D(latitude: fLat, longitude: fLng),
                        to: CLLocationCoordinate2D(latitude: tLat, longitude: tLng)
                    )
                    let path = GMSMutablePath()
                    for point in decodedPoints { path.add(point) }

                    let mode = leg?.mode ?? .walk
                    let isWalkMode = mode == .walk
                    let polyline = GMSPolyline(path: path)
                    polyline.map = mapView
                    let travelColor: UIColor = isWalkMode ? Self.paletteColor(.walk) : (mode == .car ? .systemBlue : Self.paletteColor(mode))
                    let travelWidth: CGFloat = isWalkMode ? Self.walkStrokeWidth : Self.transitStrokeWidth
                    segments = [
                        LegPolylineSegment(polyline: polyline, path: path, length: path.length(of: .rhumb), travelColor: travelColor, travelWidth: travelWidth, mutedColor: mutedColor),
                    ]
                }

                legPolylineGroups[legKey] = LegPolylineGroup(segments: segments, totalLength: segments.reduce(0) { $0 + $1.length })
                for segment in segments { setMuted(segment) }

                if hasRealRoute, let leg, !leg.alternatives.isEmpty {
                    for alternative in leg.alternatives {
                        guard
                            let altPolylineString = alternative.polyline,
                            let altDecoded = GMSPath(fromEncodedPath: altPolylineString), altDecoded.count() > 0
                        else { continue }
                        let altPolyline = GMSPolyline(path: altDecoded)
                        altPolyline.strokeWidth = 2
                        altPolyline.strokeColor = UIColor.systemGray.withAlphaComponent(0.55)
                        altPolyline.zIndex = -1
                        altPolyline.map = mapView
                        alternativePolylines.append(altPolyline)
                    }
                }
            }

            fitAll(items: items, mapView: mapView)
        }

        private func drawSteppedPolylines(for leg: RouteLeg, mutedColor: UIColor, mapView: GMSMapView) -> [LegPolylineSegment] {
            var previousStep: RouteStep?
            var result: [LegPolylineSegment] = []
            for step in leg.steps {
                guard let decoded = GMSPath(fromEncodedPath: step.polyline), decoded.count() > 0 else { continue }

                let isWalking = step.travelMode == "WALKING"
                let color: UIColor
                if isWalking {
                    color = Self.paletteColor(.walk)
                } else if let hex = step.lineColor {
                    color = UIColor(hex: hex)
                } else {
                    color = Self.modeColor(forVehicleType: step.vehicleType)
                }
                let width: CGFloat = isWalking ? Self.walkStrokeWidth : Self.transitStrokeWidth

                let polyline = GMSPolyline(path: decoded)
                polyline.map = mapView
                result.append(LegPolylineSegment(polyline: polyline, path: decoded, length: decoded.length(of: .rhumb), travelColor: color, travelWidth: width, mutedColor: mutedColor))

                if let previousStep, Self.isModeChange(from: previousStep, to: step) {
                    addTransferMarker(at: decoded.coordinate(at: 0), color: color, mapView: mapView)
                }
                previousStep = step
            }
            return result
        }

        private static func isModeChange(from previous: RouteStep, to current: RouteStep) -> Bool {
            if previous.travelMode != current.travelMode { return true }
            if previous.travelMode == "TRANSIT", previous.vehicleType != current.vehicleType { return true }
            return false
        }

        private func addTransferMarker(at coordinate: CLLocationCoordinate2D, color: UIColor, mapView: GMSMapView) {
            let marker = GMSMarker(position: coordinate)
            marker.iconView = Self.makeTransferDotView(color: color)
            marker.zIndex = 50
            marker.map = mapView
            transferMarkers.append(marker)
        }

        private static func makeTransferDotView(color: UIColor) -> UIView {
            let diameter: CGFloat = 8
            let ringDiameter = diameter + 4
            let ring = UIView(frame: CGRect(x: 0, y: 0, width: ringDiameter, height: ringDiameter))
            ring.backgroundColor = .white
            ring.layer.cornerRadius = ringDiameter / 2
            ring.layer.shadowColor = UIColor.black.cgColor
            ring.layer.shadowOpacity = 0.25
            ring.layer.shadowRadius = 1.5
            ring.layer.shadowOffset = CGSize(width: 0, height: 1)

            let dot = UIView(frame: CGRect(x: 2, y: 2, width: diameter, height: diameter))
            dot.backgroundColor = color
            dot.layer.cornerRadius = diameter / 2
            ring.addSubview(dot)
            return ring
        }

        private static func modeColor(forVehicleType vehicleType: String?) -> UIColor {
            switch vehicleType {
            case "SUBWAY", "METRO_RAIL": return paletteColor(.metro)
            case "TRAM", "LIGHT_RAIL": return paletteColor(.tram)
            case "BUS", "INTERCITY_BUS", "TROLLEYBUS", "SHARE_TAXI": return paletteColor(.bus)
            case "HEAVY_RAIL", "RAIL", "COMMUTER_TRAIN", "HIGH_SPEED_TRAIN", "LONG_DISTANCE_TRAIN": return paletteColor(.train)
            case "FUNICULAR": return paletteColor(.funicular)
            case "GONDOLA_LIFT", "CABLE_CAR": return paletteColor(.gondola)
            case "FERRY": return paletteColor(.boat)
            default: return paletteColor(.train)
            }
        }

        private static let transitStrokeWidth: CGFloat = 10
        private static let walkStrokeWidth: CGFloat = 6
        private static let mutedStrokeWidth: CGFloat = 4

        private static let dashScreenLength: Double = 8
        private static let maxDashSpanCount = 200.0

        private func setMuted(_ segment: LegPolylineSegment) {
            segment.polyline.strokeWidth = Self.mutedStrokeWidth
            segment.polyline.strokeColor = segment.mutedColor
            if !mutedPolylines.contains(where: { $0.polyline === segment.polyline }) {
                mutedPolylines.append((segment.polyline, segment.path, segment.mutedColor))
            }
            Self.setDashSpans(on: segment.polyline, path: segment.path, color: segment.mutedColor, zoom: mapView?.camera.zoom ?? 12)
        }

        private func setTraveled(_ segment: LegPolylineSegment) {
            mutedPolylines.removeAll { $0.polyline === segment.polyline }
            segment.polyline.strokeWidth = segment.travelWidth
            segment.polyline.strokeColor = segment.travelColor
            segment.polyline.spans = nil
        }

        private func setPartiallyTraveled(_ segment: LegPolylineSegment, localFraction: Double) {
            mutedPolylines.removeAll { $0.polyline === segment.polyline }
            segment.polyline.strokeWidth = segment.travelWidth
            guard segment.length > 1 else {
                setTraveled(segment)
                return
            }
            let travelLength = max(min(segment.length * localFraction, segment.length), 0.1)
            let remaining = max(segment.length - travelLength, 0.1)
            let styles = [GMSStrokeStyle.solidColor(segment.travelColor), GMSStrokeStyle.solidColor(Self.paletteColor(.walk))]
            segment.polyline.spans = GMSStyleSpans(segment.path, styles, [NSNumber(value: travelLength), NSNumber(value: remaining)], .rhumb)
        }

        private func unstyleLeg(_ legID: String) {
            guard let group = legPolylineGroups[legID] else { return }
            for segment in group.segments { setMuted(segment) }
        }

        private func styleLeg(_ legID: String, fraction: Double) {
            guard let group = legPolylineGroups[legID] else { return }
            let clamped = min(max(fraction, 0), 1)
            let travelDistance = group.totalLength * clamped
            var consumed = 0.0
            for segment in group.segments {
                let segStart = consumed
                consumed += segment.length
                let segEnd = consumed

                if travelDistance <= segStart {
                    setMuted(segment)
                } else if travelDistance >= segEnd {
                    setTraveled(segment)
                } else {
                    let localFraction = segment.length > 0 ? (travelDistance - segStart) / segment.length : 1
                    setPartiallyTraveled(segment, localFraction: localFraction)
                }
            }
        }

        private func refreshMutedDashLengths(zoom: Float) {
            for (polyline, path, color) in mutedPolylines {
                Self.setDashSpans(on: polyline, path: path, color: color, zoom: zoom)
            }
        }

        private static func setDashSpans(on polyline: GMSPolyline, path: GMSPath, color: UIColor, zoom: Float) {
            guard zoom.isFinite else { return }

            let pathLength = path.length(of: .rhumb)
            guard pathLength > 1 else { return }

            let latitude = path.coordinate(at: 0).latitude
            guard latitude.isFinite else { return }

            let metersPerPixel = 156_543.03392 * cos(latitude * .pi / 180) / pow(2.0, Double(zoom))
            let screenScaledLength = dashScreenLength * metersPerPixel
            let estimatedSpanCount = pathLength / (screenScaledLength * 2)
            let dashLength = estimatedSpanCount > maxDashSpanCount
                ? max(pathLength / maxDashSpanCount, 1)
                : max(screenScaledLength, 1)
            guard dashLength.isFinite, dashLength > 0 else { return }

            let styles = [GMSStrokeStyle.solidColor(color), GMSStrokeStyle.solidColor(.clear)]
            polyline.spans = GMSStyleSpans(path, styles, [NSNumber(value: dashLength), NSNumber(value: dashLength)], .rhumb)
        }

        private static func paletteColor(_ mode: TransportMode) -> UIColor {
            switch mode {
            case .walk: return WaypinTheme.brandNavyUIColor
            case .metro: return UIColor(hex: "#0072CE")
            case .tram: return UIColor(hex: "#00A651")
            case .bus: return UIColor(hex: "#F5A623")
            case .train: return UIColor(hex: "#D0021B")
            case .funicular: return UIColor(hex: "#8B572A")
            case .gondola: return UIColor(hex: "#17A2B8")
            case .boat: return UIColor(hex: "#20B2AA")
            case .cograil: return UIColor(hex: "#6B4E9E")
            case .car, .start: return .systemGray
            }
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            guard let itemID = marker.userData as? ItineraryItem.ID else { return false }
            onMarkerTapped?(itemID)
            return true
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            refreshMutedDashLengths(zoom: position.zoom)
            engine?.cameraDidBecomeIdle()
        }
    }
}
