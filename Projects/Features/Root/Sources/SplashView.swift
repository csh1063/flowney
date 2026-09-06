import DesignSystem
import SwiftUI

struct SplashView: View {
    @State private var pinVisible = false
    @State private var routeProgress: CGFloat = 0
    @State private var wordmarkVisible = false

    fileprivate static let points: [CGPoint] = [
        CGPoint(x: 230, y: 310),
        CGPoint(x: 410, y: 660),
        CGPoint(x: 512, y: 430),
        CGPoint(x: 614, y: 660),
        CGPoint(x: 794, y: 310),
    ]
    fileprivate static let pinHeadOffset = CGPoint(x: 0, y: -190)
    private static let pinRadius: CGFloat = 55
    private static let holeRadius: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width * 0.72, proxy.size.height * 0.44)
            let origin = CGPoint(x: (proxy.size.width - side) / 2, y: proxy.size.height * 0.22)
            let scale = side / 1024

            let mapped = Self.points.map { Self.mapPoint($0, origin: origin, scale: scale) }
            let mappedRadius = Self.pinRadius * scale
            let mappedHole = Self.holeRadius * scale

            ZStack {
                Path { path in
                    path.move(to: mapped[0])
                    for point in mapped.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .trim(from: 0, to: routeProgress)
                .stroke(
                    WaypinTheme.accent,
                    style: StrokeStyle(lineWidth: 10 * scale, lineCap: .round, lineJoin: .round, dash: [2, 22 * scale])
                )

                TravelingPin(
                    progress: routeProgress, origin: origin, scale: scale,
                    radius: mappedRadius, holeRadius: mappedHole
                )
                .opacity(pinVisible ? 1 : 0)

                VStack(spacing: 8) {
                    Spacer()
                    Text("Waypin")
                        .font(.system(size: 32, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: "#F5F1E6"))
                        .tracking(2)
                    Text("여행의 모든 순간을 하나의 경로로")
                        .font(WaypinFont.body)
                        .foregroundStyle(WaypinTheme.accent.opacity(0.8))
                }
                .opacity(wordmarkVisible ? 1 : 0)
                .padding(.bottom, proxy.size.height * 0.32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WaypinTheme.brandNavy)
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animate()
            }
        }
    }

    fileprivate static func mapPoint(_ point: CGPoint, origin: CGPoint, scale: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + point.x * scale, y: origin.y + point.y * scale)
    }

    fileprivate static func wedgePath(tip: CGPoint, head: CGPoint, radius: CGFloat) -> Path {
        let dx = head.x - tip.x
        let dy = head.y - tip.y
        let d = max(hypot(dx, dy), radius + 1)
        let alpha = asin(min(radius / d, 1))
        let theta = atan2(dy, dx)
        let length = sqrt(max(d * d - radius * radius, 0))

        let angle1 = theta + alpha
        let angle2 = theta - alpha
        let point1 = CGPoint(x: tip.x + length * cos(angle1), y: tip.y + length * sin(angle1))
        let point2 = CGPoint(x: tip.x + length * cos(angle2), y: tip.y + length * sin(angle2))

        var path = Path()
        path.move(to: tip)
        path.addLine(to: point1)
        path.addLine(to: point2)
        path.closeSubpath()
        return path
    }

    fileprivate static func pointAlongRoute(progress: CGFloat) -> CGPoint {
        let segmentLengths = zip(points, points.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) }
        let total = segmentLengths.reduce(0, +)
        var target = max(0, min(progress, 1)) * total
        for (index, length) in segmentLengths.enumerated() {
            if target <= length || index == segmentLengths.count - 1 {
                let t = length > 0 ? target / length : 0
                let p0 = points[index]
                let p1 = points[index + 1]
                return CGPoint(x: p0.x + (p1.x - p0.x) * t, y: p0.y + (p1.y - p0.y) * t)
            }
            target -= length
        }
        return points.last ?? .zero
    }

    private func animate() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            pinVisible = true
        }
        withAnimation(.linear(duration: 1.8).delay(0.35)) {
            routeProgress = 1
        }
        withAnimation(.easeOut(duration: 0.5).delay(2.35)) {
            wordmarkVisible = true
        }
    }
}

private struct TravelingPin: View, Animatable {
    var progress: CGFloat
    let origin: CGPoint
    let scale: CGFloat
    let radius: CGFloat
    let holeRadius: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let tip = SplashView.mapPoint(SplashView.pointAlongRoute(progress: progress), origin: origin, scale: scale)
        let head = CGPoint(
            x: tip.x + SplashView.pinHeadOffset.x * scale,
            y: tip.y + SplashView.pinHeadOffset.y * scale
        )

        ZStack {
            SplashView.wedgePath(tip: tip, head: head, radius: radius)
                .fill(WaypinTheme.accent)
            Circle()
                .fill(WaypinTheme.accent)
                .frame(width: radius * 2, height: radius * 2)
                .position(head)
            Circle()
                .fill(WaypinTheme.brandNavy)
                .frame(width: holeRadius * 2, height: holeRadius * 2)
                .position(head)
        }
    }
}

#Preview {
    SplashView()
}
