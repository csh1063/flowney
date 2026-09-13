import DesignSystem
import SwiftUI

struct SplashView: View {
    @State private var mapVisible = false
    @State private var trailProgress: CGFloat = 0
    @State private var planeVisible = false
    @State private var planeProgress: CGFloat = 0
    @State private var wordmarkVisible = false

    private static let navy = Color(hex: "#121E36")
    private static let gold = Color(hex: "#D4AF37")

    private static let trailStart = CGPoint(x: 110, y: 350)
    private static let trailControl1 = CGPoint(x: 170, y: 180)
    private static let trailControl2 = CGPoint(x: 250, y: 160)
    private static let trailMid = CGPoint(x: 310, y: 260)
    private static let trailControl3 = CGPoint(x: 350, y: 320)
    private static let trailControl4 = CGPoint(x: 380, y: 270)
    private static let trailEnd = CGPoint(x: 400, y: 210)

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width * 0.72, proxy.size.height * 0.44)
            let origin = CGPoint(x: (proxy.size.width - side) / 2, y: proxy.size.height * 0.22)
            let scale = side / 512

            ZStack {
                Canvas { context, _ in
                    let transform = Self.mapTransform(origin: origin, scale: scale)
                    context.stroke(
                        Self.worldMapPath().applying(transform),
                        with: .color(Self.gold),
                        lineWidth: 3 * scale
                    )
                }
                .opacity(mapVisible ? 0.15 : 0)

                AnimatedTrail(progress: trailProgress, origin: origin, scale: scale)

                TravelingPlane(progress: planeProgress, origin: origin, scale: scale)
                    .opacity(planeVisible ? 1 : 0)

                VStack(spacing: 8) {
                    Spacer()
                    Text("Flowney")
                        .font(.system(size: 32, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: "#F5F1E6"))
                        .tracking(2)
                    Text("여행의 모든 순간을 하나의 경로로")
                        .font(FlowneyFont.body)
                        .foregroundStyle(Self.gold.opacity(0.8))
                }
                .opacity(wordmarkVisible ? 1 : 0)
                .offset(y: wordmarkVisible ? 0 : 10)
                .padding(.bottom, proxy.size.height * 0.32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Self.navy)
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animate()
            }
        }
    }

    private static func mapTransform(origin: CGPoint, scale: CGFloat) -> CGAffineTransform {
        CGAffineTransform(translationX: origin.x, y: origin.y).scaledBy(x: scale, y: scale)
    }

    private static func worldMapPath() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 120, y: 180))
        path.addQuadCurve(to: CGPoint(x: 200, y: 220), control: CGPoint(x: 160, y: 160))
        path.addQuadCurve(to: CGPoint(x: 260, y: 300), control: CGPoint(x: 240, y: 280))
        path.addQuadCurve(to: CGPoint(x: 320, y: 280), control: CGPoint(x: 280, y: 320))
        path.addQuadCurve(to: CGPoint(x: 340, y: 360), control: CGPoint(x: 360, y: 240))

        path.move(to: CGPoint(x: 360, y: 140))
        path.addQuadCurve(to: CGPoint(x: 390, y: 260), control: CGPoint(x: 400, y: 180))
        path.addQuadCurve(to: CGPoint(x: 430, y: 380), control: CGPoint(x: 380, y: 340))
        path.addQuadCurve(to: CGPoint(x: 460, y: 420), control: CGPoint(x: 480, y: 420))
        return path
    }

    fileprivate static func trailPath() -> Path {
        var path = Path()
        path.move(to: trailStart)
        path.addCurve(to: trailMid, control1: trailControl1, control2: trailControl2)
        path.addCurve(to: trailEnd, control1: trailControl3, control2: trailControl4)
        return path
    }

    fileprivate static func pointAndAngle(progress: CGFloat) -> (point: CGPoint, angle: CGFloat) {
        let clamped = max(0, min(progress, 1))
        let len1 = approximateLength(trailStart, trailControl1, trailControl2, trailMid)
        let len2 = approximateLength(trailMid, trailControl3, trailControl4, trailEnd)
        let total = len1 + len2
        let target = clamped * total

        if target <= len1 {
            let t = len1 > 0 ? target / len1 : 0
            return (
                cubicPoint(trailStart, trailControl1, trailControl2, trailMid, t),
                cubicAngle(trailStart, trailControl1, trailControl2, trailMid, t)
            )
        } else {
            let t = len2 > 0 ? (target - len1) / len2 : 1
            return (
                cubicPoint(trailMid, trailControl3, trailControl4, trailEnd, t),
                cubicAngle(trailMid, trailControl3, trailControl4, trailEnd, t)
            )
        }
    }

    private static func approximateLength(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, samples: Int = 24) -> CGFloat {
        var length: CGFloat = 0
        var previous = p0
        for i in 1...samples {
            let t = CGFloat(i) / CGFloat(samples)
            let point = cubicPoint(p0, p1, p2, p3, t)
            length += hypot(point.x - previous.x, point.y - previous.y)
            previous = point
        }
        return length
    }

    private static func cubicPoint(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let x = mt * mt * mt * p0.x + 3 * mt * mt * t * p1.x + 3 * mt * t * t * p2.x + t * t * t * p3.x
        let y = mt * mt * mt * p0.y + 3 * mt * mt * t * p1.y + 3 * mt * t * t * p2.y + t * t * t * p3.y
        return CGPoint(x: x, y: y)
    }

    private static func cubicAngle(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ t: CGFloat) -> CGFloat {
        let mt = 1 - t
        let dx = 3 * mt * mt * (p1.x - p0.x) + 6 * mt * t * (p2.x - p1.x) + 3 * t * t * (p3.x - p2.x)
        let dy = 3 * mt * mt * (p1.y - p0.y) + 6 * mt * t * (p2.y - p1.y) + 3 * t * t * (p3.y - p2.y)
        return atan2(dy, dx)
    }

    private func animate() {
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            mapVisible = true
        }
        planeVisible = true
        withAnimation(.timingCurve(0.25, 1, 0.5, 1, duration: 1.35).delay(0.62)) {
            planeProgress = 1
        }
        withAnimation(.timingCurve(0.25, 1, 0.5, 1, duration: 1.35).delay(0.62)) {
            trailProgress = 1
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.6)) {
            wordmarkVisible = true
        }
    }
}

private struct AnimatedTrail: View, Animatable {
    var progress: CGFloat
    let origin: CGPoint
    let scale: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, _ in
            let transform = CGAffineTransform(translationX: origin.x, y: origin.y).scaledBy(x: scale, y: scale)
            let trail = SplashView.trailPath().applying(transform).trimmedPath(from: 0, to: progress)
            let gold = Color(hex: "#D4AF37")
            context.stroke(trail, with: .color(gold.opacity(0.12)), style: StrokeStyle(lineWidth: 28 * scale, lineCap: .round))
            context.stroke(trail, with: .color(gold), style: StrokeStyle(lineWidth: 14 * scale, lineCap: .round))
        }
    }
}

private struct TravelingPlane: View, Animatable {
    var progress: CGFloat
    let origin: CGPoint
    let scale: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let (point, angle) = SplashView.pointAndAngle(progress: progress)
        let position = CGPoint(x: origin.x + point.x * scale, y: origin.y + point.y * scale)

        Canvas { context, size in
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .radians(angle + .pi / 2))
            context.scaleBy(x: scale * 1.2, y: scale * 1.2)
            context.fill(Self.planePath(), with: .color(Color(hex: "#D4AF37")))
        }
        .frame(width: 160, height: 160)
        .position(position)
    }

    /// 원본 SVG의 plane path를 그대로 옮김 — 로컬 원점(0,0)이 시각적 중심에 오도록 이미 대칭으로 그려져 있음.
    private static func planePath() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: -42))
        path.addCurve(to: CGPoint(x: 7.5, y: -24), control1: CGPoint(x: 5, y: -42), control2: CGPoint(x: 7.5, y: -34))
        path.addLine(to: CGPoint(x: 7.5, y: -8))
        path.addLine(to: CGPoint(x: 46, y: 10))
        path.addCurve(to: CGPoint(x: 43, y: 16), control1: CGPoint(x: 48, y: 12), control2: CGPoint(x: 48, y: 16))
        path.addLine(to: CGPoint(x: 7.5, y: 6))
        path.addLine(to: CGPoint(x: 7.5, y: 24))
        path.addLine(to: CGPoint(x: 20, y: 34))
        path.addCurve(to: CGPoint(x: 17, y: 38), control1: CGPoint(x: 22, y: 36), control2: CGPoint(x: 22, y: 38))
        path.addLine(to: CGPoint(x: 0, y: 32))
        path.addLine(to: CGPoint(x: -17, y: 38))
        path.addCurve(to: CGPoint(x: -20, y: 34), control1: CGPoint(x: -22, y: 38), control2: CGPoint(x: -22, y: 36))
        path.addLine(to: CGPoint(x: -7.5, y: 24))
        path.addLine(to: CGPoint(x: -7.5, y: 6))
        path.addLine(to: CGPoint(x: -46, y: 16))
        path.addCurve(to: CGPoint(x: -43, y: 10), control1: CGPoint(x: -48, y: 16), control2: CGPoint(x: -48, y: 12))
        path.addLine(to: CGPoint(x: -7.5, y: -8))
        path.addLine(to: CGPoint(x: -7.5, y: -24))
        path.addCurve(to: CGPoint(x: 0, y: -42), control1: CGPoint(x: -7.5, y: -34), control2: CGPoint(x: -5, y: -42))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SplashView()
}
