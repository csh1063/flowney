import ComposableArchitecture
import CoreLocation
import DesignSystem
import GoogleMaps
import Models
import SwiftUI

struct RouteMapView: UIViewRepresentable {
    let items: IdentifiedArrayOf<ItineraryItem>
    let legs: IdentifiedArrayOf<RouteLeg>
    /// html의 `curIdx` — nil이면 전체보기(오늘 모든 장소가 다 보이게 줌).
    let currentStopIndex: Int?
    /// "다음" 버튼/앞쪽 리스트 탭 — 마커가 currentStopIndex-1 → currentStopIndex 구간을
    /// 실제로 이동하는 애니메이션.
    let animateTrigger: Int
    /// "이전" 버튼, 뒤쪽/전체보기 탭, 날짜 경계 이동 — 애니메이션 없이 카메라만 즉시 이동.
    let jumpTrigger: Int
    let focusedItemID: ItineraryItem.ID?
    /// 하단 리스트 패널의 현재 높이 — 이만큼 지도 아래쪽이 가려져 있다는 뜻이라, 카메라를
    /// 맞출 때 이 값만큼 아래쪽 inset을 추가로 줘서 실제로 "보이는" 영역 중앙에 오게 한다.
    let bottomInset: CGFloat
    let onAnimationCompleted: () -> Void
    /// 지도 위 핀을 직접 탭했을 때 — 리스트에서 탭한 것과 동일하게 그 장소로 즉시 줌인한다.
    let onMarkerTapped: (ItineraryItem.ID) -> Void

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 37.5665, longitude: 126.9780, zoom: 12)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        context.coordinator.onMarkerTapped = onMarkerTapped
        context.coordinator.engine = TravelerAnimationEngine(mapView: mapView)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.onMarkerTapped = onMarkerTapped
        context.coordinator.update(
            items: items,
            legs: legs,
            currentStopIndex: currentStopIndex,
            animateTrigger: animateTrigger,
            jumpTrigger: jumpTrigger,
            focusedItemID: focusedItemID,
            bottomInset: bottomInset,
            onAnimationCompleted: onAnimationCompleted
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator: NSObject, GMSMapViewDelegate {
        var mapView: GMSMapView?
        var engine: TravelerAnimationEngine?
        var onMarkerTapped: ((ItineraryItem.ID) -> Void)?

        private var drawnKey = ""
        private var lastAnimateTrigger: Int?
        private var lastJumpTrigger: Int?
        private var markers: [GMSMarker] = []
        /// 대중교통 구간 안에서 이동수단이 바뀌는(환승) 지점에 찍는 작은 점 마커.
        private var transferMarkers: [GMSMarker] = []
        /// 걷기/대중교통 비교에서 추천되지 못한 대안 경로 — 항상 옅은 회색 얇은 선, 채색/점선
        /// 전환 대상이 아니다.
        private var alternativePolylines: [GMSPolyline] = []

        /// leg 하나(대중교통이면 step마다 여러 개)를 이루는 폴리라인들. 기본은 옅은 회색 점선
        /// (`setMuted`)이고, 그 구간을 실제로 지나는 애니메이션이 재생되는 동안/끝난 뒤에만
        /// `styleLeg(_:fraction:)`로 진행률만큼 채색된다.
        private struct LegPolylineSegment {
            let polyline: GMSPolyline
            let path: GMSPath
            let length: Double
            /// 채워졌을 때(지나간 구간) 쓸 색 — 걷기는 무채색(회색) 그대로, 대중교통/차는
            /// 노선색/모드색.
            let travelColor: UIColor
            let travelWidth: CGFloat
        }
        private struct LegPolylineGroup {
            var segments: [LegPolylineSegment]
            var totalLength: Double
        }
        private var legPolylineGroups: [String: LegPolylineGroup] = [:]
        /// 지금 "지금 막 지나온/지나는 중" 상태라 채색돼 있는 leg — 다음 애니메이션이 시작되거나
        /// 사용자가 핀을 다른 곳으로 옮기는 순간(점프) 다시 점선으로 되돌린다.
        private var highlightedLegID: String?
        /// 현재 옅은 회색 점선 상태인 폴리라인들 — 줌이 바뀔 때마다(카메라가 멈춘 시점) 화면상
        /// 점선 간격이 항상 일정해 보이도록 대시 길이를 다시 계산해서 여기 적용한다. 채색된
        /// (지나간/지나는 중인) 폴리라인은 여기서 빠진다.
        private var mutedPolylines: [(polyline: GMSPolyline, path: GMSPath)] = []

        func update(
            items: IdentifiedArrayOf<ItineraryItem>,
            legs: IdentifiedArrayOf<RouteLeg>,
            currentStopIndex: Int?,
            animateTrigger: Int,
            jumpTrigger: Int,
            focusedItemID: ItineraryItem.ID?,
            bottomInset: CGFloat,
            onAnimationCompleted: @escaping () -> Void
        ) {
            guard let mapView else { return }

            // 마커/연결선은 items나 legs 둘 중 하나만 바뀌어도 다시 그려야 한다 — legs가
            // 계속 비어있어도(경로 탐색 전) 장소가 추가/변경되면 핀은 항상 바로 찍혀야 하므로,
            // "legs가 바뀔 때만 다시 그림" 조건에 items 변경도 포함시킨다.
            let key = items.map(\.id.uuidString).joined(separator: ",") + "|" + legs.map(\.id).joined(separator: ",")
            if key != drawnKey {
                drawnKey = key
                redraw(items: items, legs: legs, mapView: mapView, bottomInset: bottomInset)
            }

            updateMarkerStyles(currentStopIndex: currentStopIndex)

            // 두 트리거는 서로 독립적으로 바뀔 수 있으니 각각 따로 감지한다. 초기값이 둘 다
            // nil이라 첫 update()에서 0과 비교해 우연히 애니메이션이 발동하지 않도록, 최초
            // 진입시에는 값만 기록하고 아무 것도 하지 않는다.
            let isFirstUpdate = lastAnimateTrigger == nil && lastJumpTrigger == nil
            let shouldAnimate = !isFirstUpdate && lastAnimateTrigger != animateTrigger
            let shouldJump = !isFirstUpdate && lastJumpTrigger != jumpTrigger
            lastAnimateTrigger = animateTrigger
            lastJumpTrigger = jumpTrigger

            if shouldAnimate {
                animateCurrentLeg(items: items, legs: legs, currentStopIndex: currentStopIndex, bottomInset: bottomInset, onAnimationCompleted: onAnimationCompleted)
            } else if shouldJump {
                // 점프(이전 버튼/전체보기/날짜 경계 이동 등)는 새로 채색하지 않는다 — 지금까지
                // 채색돼 있던 구간이 있으면 그 순간 다시 점선으로 되돌린다.
                if let highlightedLegID {
                    unstyleLeg(highlightedLegID)
                    self.highlightedLegID = nil
                }
                jump(to: focusedItemID, items: items, mapView: mapView, bottomInset: bottomInset)
            }
        }

        // html의 updateMarkerStates() 이식 — 지난 장소는 흐리게, 현재 장소는 파란 핀으로.
        private func updateMarkerStyles(currentStopIndex: Int?) {
            for (index, marker) in markers.enumerated() {
                guard let currentStopIndex else {
                    marker.opacity = 1
                    marker.icon = nil
                    continue
                }
                if index < currentStopIndex {
                    marker.opacity = 0.45
                    marker.icon = nil
                } else if index == currentStopIndex {
                    marker.opacity = 1
                    marker.icon = GMSMarker.markerImage(with: .systemBlue)
                } else {
                    marker.opacity = 1
                    marker.icon = nil
                }
            }
        }

        private func animateCurrentLeg(
            items: IdentifiedArrayOf<ItineraryItem>,
            legs: IdentifiedArrayOf<RouteLeg>,
            currentStopIndex: Int?,
            bottomInset: CGFloat,
            onAnimationCompleted: @escaping () -> Void
        ) {
            // legs는 "경로 탐색" 전엔 비어있고, 탐색 후에도 fromId-toId 쌍으로만 존재하는
            // 희소 배열이라 인덱스에 그대로 대응하지 않는다 — items 순서로 구간을 찾고,
            // 해당하는 실제 경로가 없으면 직선(mode는 도착 장소의 arrivalMode) 애니메이션.
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

            // 항상 "지금 막 이동한 구간 하나만" 채색돼 있게 — 새 구간 애니메이션이 시작되면
            // 이전에 채색돼 있던 구간은 먼저 다시 점선으로 되돌린다.
            if let highlightedLegID, highlightedLegID != legKey {
                unstyleLeg(highlightedLegID)
            }
            highlightedLegID = legKey

            engine?.animate(
                leg: leg,
                from: CLLocationCoordinate2D(latitude: fromLat, longitude: fromLng),
                to: CLLocationCoordinate2D(latitude: toLat, longitude: toLng),
                bottomInset: bottomInset,
                onProgress: { [weak self] fraction in
                    self?.styleLeg(legKey, fraction: fraction)
                },
                onCompleted: onAnimationCompleted
            )
        }

        private func jump(to focusedItemID: ItineraryItem.ID?, items: IdentifiedArrayOf<ItineraryItem>, mapView: GMSMapView, bottomInset: CGFloat) {
            guard let focusedItemID, let item = items[id: focusedItemID], let lat = item.lat, let lng = item.lng else {
                // 전체보기로 돌아간 경우(포커스된 장소 없음) — 오늘 모든 장소가 다 보이게.
                fitAll(items: items, mapView: mapView, bottomInset: bottomInset)
                return
            }
            let target = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let jumpZoom: Float = 15
            let shifted = Self.shiftCoordinate(target, upBy: bottomInset / 2, zoom: jumpZoom)
            let camera = GMSCameraPosition.camera(withTarget: shifted, zoom: jumpZoom)
            mapView.animate(to: camera)
        }

        private func fitAll(items: IdentifiedArrayOf<ItineraryItem>, mapView: GMSMapView, bottomInset: CGFloat) {
            var bounds = GMSCoordinateBounds()
            var hasAny = false
            for item in items {
                guard let lat = item.lat, let lng = item.lng else { continue }
                bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                hasAny = true
            }
            guard hasAny else { return }
            let edgeInsets = UIEdgeInsets(top: 64, left: 64, bottom: 64 + bottomInset, right: 64)
            mapView.animate(with: GMSCameraUpdate.fit(bounds, with: edgeInsets))
        }

        // 화면상 screenOffset 포인트만큼 "위로" 보이도록, 목표 좌표를 미리 그만큼 밀어서
        // 돌려준다 — 하단 리스트 패널에 가려지지 않고 실제로 보이는 영역 중앙에 오게 하기 위함.
        //
        // 이전엔 `mapView.projection`(카메라를 옮기기 "전"의, 즉 이전 줌 레벨의 투영)을 기준으로
        // 픽셀→좌표 변환을 했는데, 전체보기(줌아웃) 상태에서 특정 장소로 점프하거나 날짜 경계를
        // 넘어 완전히 다른 줌 레벨에서 오는 경우 이전 줌과 점프 후 줌(15)이 크게 달라서 같은
        // screenOffset 픽셀이 실제로는 훨씬 다른 지리적 거리로 계산돼 어긋났다(목표 지점이
        // 리스트 쪽으로 치우쳐 찍힘). 대신 "점프 후 확정된 줌 레벨" 기준으로 Web Mercator
        // 미터/픽셀 근사식을 직접 써서, 현재 카메라 상태와 무관하게 항상 같은 결과가 나오도록 한다.
        private static func shiftCoordinate(_ coordinate: CLLocationCoordinate2D, upBy screenOffset: CGFloat, zoom: Float) -> CLLocationCoordinate2D {
            guard screenOffset > 1 else { return coordinate }
            let metersPerPixel = 156_543.03392 * cos(coordinate.latitude * .pi / 180) / pow(2.0, Double(zoom))
            let shiftMeters = Double(screenOffset) * metersPerPixel
            let shiftLatDegrees = shiftMeters / 111_320.0
            // 화면 아래쪽(리스트)에서 멀어지도록 목표보다 남쪽을 카메라 중심으로 삼으면,
            // 목표 지점은 상대적으로 화면 위쪽(북쪽 방향)에 나타난다.
            return CLLocationCoordinate2D(latitude: coordinate.latitude - shiftLatDegrees, longitude: coordinate.longitude)
        }

        private func redraw(items: IdentifiedArrayOf<ItineraryItem>, legs: IdentifiedArrayOf<RouteLeg>, mapView: GMSMapView, bottomInset: CGFloat) {
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
                guard let lat = item.lat, let lng = item.lng else { continue }
                let position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                let marker = GMSMarker(position: position)
                marker.title = "\(index + 1). \(item.name)"
                marker.userData = item.id
                marker.map = mapView
                markers.append(marker)
            }

            // 기본은 항상 인접한 장소끼리 직선으로 연결하고, "경로 탐색"으로 받아온 실제 경로
            // (status == .ok)가 있는 구간만 그 폴리라인으로 대체한다. 모든 구간은 일단 옅은
            // 회색 점선(실제 경로를 따라감)으로 그려두고, 그 구간을 지나는 애니메이션이
            // 재생될 때만 `styleLeg`가 진행률만큼 채색한다 — 평소엔 색이 너무 많아 복잡해
            // 보이던 걸 "지금 이동 중/막 이동한 구간"만 눈에 띄게 바꾼 것.
            for index in 0 ..< max(items.count - 1, 0) {
                let fromItem = items[index]
                let toItem = items[index + 1]
                guard
                    let fLat = fromItem.lat, let fLng = fromItem.lng,
                    let tLat = toItem.lat, let tLng = toItem.lng
                else { continue }

                let leg = legs[id: "\(fromItem.id)-\(toItem.id)"]
                let legKey = leg?.id ?? "\(fromItem.id)-\(toItem.id)"
                let hasRealRoute = leg?.status == .ok

                // 대중교통 계열(버스/지하철/트램/기차/…)이고 구간별 steps가 있으면, 한 폴리라인이
                // 아니라 step마다 나눠서 각자 채색 색(노선색/모드색)을 미리 정해둔다 — 그 안에서
                // 수단이 바뀌는 지점(환승)에는 작은 점 마커도 찍는다. 그 외(걷기/차 단일 모드,
                // steps 없음, 직선)는 통짜 폴리라인 하나.
                let segments: [LegPolylineSegment]
                if hasRealRoute, let leg, Self.isTransitVehicleMode(leg.mode), !leg.steps.isEmpty {
                    segments = drawSteppedPolylines(for: leg, mapView: mapView)
                } else {
                    let path: GMSMutablePath
                    if let polylineString = leg?.polyline, hasRealRoute, let decoded = GMSPath(fromEncodedPath: polylineString), decoded.count() > 0 {
                        path = GMSMutablePath(path: decoded)
                    } else {
                        path = GMSMutablePath()
                        path.add(CLLocationCoordinate2D(latitude: fLat, longitude: fLng))
                        path.add(CLLocationCoordinate2D(latitude: tLat, longitude: tLng))
                    }

                    let mode = leg?.mode ?? .walk
                    let isWalkMode = mode == .walk
                    let polyline = GMSPolyline(path: path)
                    polyline.map = mapView
                    // 채워졌을 때(막 지나온 구간) 쓸 색 — 걷기는 실제로 지나갔어도 여전히
                    // 무채색(점선→실선으로만 구분), 차/대중교통(steps 없는 경우)은 각자 색.
                    let travelColor: UIColor = isWalkMode ? Self.paletteColor(.walk) : (mode == .car ? .systemBlue : Self.paletteColor(mode))
                    let travelWidth: CGFloat = isWalkMode ? Self.walkStrokeWidth : Self.transitStrokeWidth
                    segments = [
                        LegPolylineSegment(polyline: polyline, path: path, length: path.length(of: .rhumb), travelColor: travelColor, travelWidth: travelWidth),
                    ]
                }

                legPolylineGroups[legKey] = LegPolylineGroup(segments: segments, totalLength: segments.reduce(0) { $0 + $1.length })
                for segment in segments { setMuted(segment) }

                // 걷기 vs 대중교통 비교에서 추천되지 못한 나머지 경로들 — 옅은 회색 얇은 선으로
                // 추천 경로 뒤에 같이 그린다. 채색/점선 전환 대상이 아니라 항상 이 모습 그대로.
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

            fitAll(items: items, mapView: mapView, bottomInset: bottomInset)
        }

        private static func isTransitVehicleMode(_ mode: TransportMode) -> Bool {
            switch mode {
            case .tram, .metro, .train, .bus, .gondola, .funicular, .boat: return true
            case .walk, .car, .start: return false
            }
        }

        // leg 하나를 step 단위로 나눠서, 실제 탄 구간(TRANSIT)은 노선색(또는 이동수단 기본색),
        // 역까지 걷는 구간(WALKING)은 무채색으로 "채워졌을 때 쓸 색"만 미리 정해둔다 — 실제
        // 점선/채색 적용은 호출한 쪽에서 `setMuted`/`styleLeg`가 한다. 인접한 두 step 사이에
        // 수단이 바뀌면(예: 버스→지하철, 걷기→기차) 그 경계에 작은 점 마커를 찍는다.
        private func drawSteppedPolylines(for leg: RouteLeg, mapView: GMSMapView) -> [LegPolylineSegment] {
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
                result.append(LegPolylineSegment(polyline: polyline, path: decoded, length: decoded.length(of: .rhumb), travelColor: color, travelWidth: width))

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

        // Google `transit_details.line.color`가 없는 지역/노선을 위한 이동수단별 기본 색.
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

        private static let transitStrokeWidth: CGFloat = 12
        private static let walkStrokeWidth: CGFloat = 8
        /// 기본(아직 안 지나간) 상태 굵기 — 모드 상관없이 다 이 굵기의 옅은 회색 점선으로
        /// 통일해서 평소엔 지도가 복잡해 보이지 않게 한다.
        private static let mutedStrokeWidth: CGFloat = 4

        // 점선 간격이 화면상 항상 같은 크기로 보이도록, 실제 거리(m) 대신 "화면 픽셀 몇 개
        // 만큼"을 기준으로 잡고 그때그때 줌 레벨에 맞는 실거리로 환산한다 — 줌아웃하면 대시가
        // 성기게, 줌인하면 촘촘하게 보이던 문제(고정 미터값의 한계)를 없앤다. 카메라가 멈출
        // 때마다(idleAt) `refreshMutedDashLengths`가 이미 그려진 점선들을 다시 계산해서 적용한다.
        private static let dashScreenLength: Double = 8
        // 국가 이동일 같은 아주 긴 직선(검색 실패한 fallback 등, 수백 km)에 화면 기준 촘촘한
        // 간격을 그대로 쓰면 GMSStyleSpans가 span을 수만 개 만들어내 메모리를 터뜨리는
        // (SIGKILL) 문제가 있었으므로, 그 경우에만 거리에 비례해서 대시 개수를 제한한다.
        private static let maxDashSpanCount = 200.0

        /// 아직 지나가지 않은(또는 다시 점선으로 되돌아간) 기본 상태 — 옅은 회색 점선.
        private func setMuted(_ segment: LegPolylineSegment) {
            segment.polyline.strokeWidth = Self.mutedStrokeWidth
            segment.polyline.strokeColor = Self.paletteColor(.walk)
            if !mutedPolylines.contains(where: { $0.polyline === segment.polyline }) {
                mutedPolylines.append((segment.polyline, segment.path))
            }
            Self.setDashSpans(on: segment.polyline, path: segment.path, zoom: mapView?.camera.zoom ?? 12)
        }

        /// 완전히 지나간 상태 — 실선 + 채색.
        private func setTraveled(_ segment: LegPolylineSegment) {
            mutedPolylines.removeAll { $0.polyline === segment.polyline }
            segment.polyline.strokeWidth = segment.travelWidth
            segment.polyline.strokeColor = segment.travelColor
            segment.polyline.spans = nil
        }

        /// 지금 막 지나는 중인 구간 — 지나온 만큼(`localFraction`)은 채색 실선, 나머지는
        /// 무채색 실선(점선 계산 없이 단순 2단 스팬 — 어차피 애니메이션이 도는 몇 초 사이만
        /// 잠깐 보이는 상태라 굳이 줌 연동 점선까지는 필요 없다).
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

        /// 해당 leg를 다시 기본(점선) 상태로 되돌린다.
        private func unstyleLeg(_ legID: String) {
            guard let group = legPolylineGroups[legID] else { return }
            for segment in group.segments { setMuted(segment) }
        }

        /// 0→1 진행률에 맞춰 leg의 폴리라인(들)을 채색한다 — 여러 step으로 나뉜 leg는 누적
        /// 길이 기준으로 "이미 지난 step은 완전 채색 / 지금 지나는 step은 부분 채색 / 아직인
        /// step은 그대로 점선"으로 나눈다.
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

        /// 카메라 줌이 바뀔 때마다 이미 그려진(아직 채색 안 된) 점선들의 간격을 새 줌 기준으로
        /// 다시 맞춘다. 채색된 구간은 실선이라 줌과 무관하다.
        private func refreshMutedDashLengths(zoom: Float) {
            for (polyline, path) in mutedPolylines {
                Self.setDashSpans(on: polyline, path: path, zoom: zoom)
            }
        }

        private static func setDashSpans(on polyline: GMSPolyline, path: GMSPath, zoom: Float) {
            let pathLength = path.length(of: .rhumb)
            guard pathLength > 1 else { return }

            let latitude = path.coordinate(at: 0).latitude
            let metersPerPixel = 156_543.03392 * cos(latitude * .pi / 180) / pow(2.0, Double(zoom))
            let screenScaledLength = dashScreenLength * metersPerPixel
            let estimatedSpanCount = pathLength / (screenScaledLength * 2)
            let dashLength = estimatedSpanCount > maxDashSpanCount
                ? max(pathLength / maxDashSpanCount, 1)
                : max(screenScaledLength, 1)

            let styles = [GMSStrokeStyle.solidColor(paletteColor(.walk)), GMSStrokeStyle.solidColor(.clear)]
            polyline.spans = GMSStyleSpans(path, styles, [NSNumber(value: dashLength), NSNumber(value: dashLength)], .rhumb)
        }

        private static func paletteColor(_ mode: TransportMode) -> UIColor {
            switch mode {
            case .walk: return UIColor(hex: "#8E8E93")
            case .metro: return UIColor(hex: "#0072CE")
            case .tram: return UIColor(hex: "#00A651")
            case .bus: return UIColor(hex: "#F5A623")
            case .train: return UIColor(hex: "#D0021B")
            case .funicular: return UIColor(hex: "#8B572A")
            case .gondola: return UIColor(hex: "#17A2B8")
            case .boat: return UIColor(hex: "#20B2AA")
            case .car, .start: return .systemGray
            }
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            guard let itemID = marker.userData as? ItineraryItem.ID else { return false }
            onMarkerTapped?(itemID)
            return true
        }

        // 드래그/핀치 중엔 계속 안 부르고 카메라가 멈춘 시점에 한 번만 불러서, 걷기 점선
        // 간격을 매 프레임 다시 계산하는 성능 부담 없이 줌 변화에 맞춰 갱신한다.
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            refreshMutedDashLengths(zoom: position.zoom)
        }
    }
}
