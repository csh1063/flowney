import SwiftUI

/// 세션 확인(`AuthFeature.State.isCheckingSession`)이 끝날 때까지 잠깐 보여주는 화면.
/// 실제 앱 아이콘 PNG를 에셋으로 새로 번들링하는 대신, 같은 네이비+골드 여권 모티프를
/// SwiftUI 도형으로 그대로 재현했다 — 모듈 간 리소스 번들 설정 없이 어디서든 바로 쓸 수
/// 있고, 아이콘과 똑같은 색 토큰(`WaypinTheme`)을 쓰니 실제 아이콘과 시각적으로 일치한다.
public struct SplashView: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            iconGlyph
                .frame(width: 96, height: 96)
                // 중앙보다 살짝 위 — 화면 세로 중심에서 8% 정도 위로.
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.42)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WaypinTheme.brandNavy)
        .ignoresSafeArea()
    }

    private var iconGlyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(WaypinTheme.brandGold, lineWidth: 4)

            Circle()
                .fill(WaypinTheme.brandGold)
                .frame(width: 56, height: 56)

            pinShape
                .fill(WaypinTheme.brandNavy)
                .frame(width: 26, height: 32)
                .offset(y: -2)

            Circle()
                .fill(WaypinTheme.brandGold)
                .frame(width: 10, height: 10)
                .offset(y: -8)
        }
    }

    private var pinShape: some Shape {
        Path { path in
            let width: CGFloat = 26
            let height: CGFloat = 32
            path.addEllipse(in: CGRect(x: 0, y: 0, width: width, height: width))
            path.move(to: CGPoint(x: width * 0.2, y: width * 0.6))
            path.addLine(to: CGPoint(x: width / 2, y: height))
            path.addLine(to: CGPoint(x: width * 0.8, y: width * 0.6))
            path.closeSubpath()
        }
    }
}

#Preview {
    SplashView()
}
