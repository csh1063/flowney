import DesignSystem
import SwiftUI

/// 세션 확인(`AuthFeature.State.isCheckingSession`)이 끝날 때까지 잠깐 보여주는 화면.
/// `RootView`에서만 쓰는 단일 소비자라 Root 모듈 소유로 두고, 실제 앱 아이콘 에셋
/// (`SplashIcon` — `AppIcon.appiconset`과 같은 PNG를 공유)을 그대로 그린다.
struct SplashView: View {
    var body: some View {
        GeometryReader { proxy in
            Image("SplashIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                // 중앙보다 살짝 위 — 화면 세로 중심에서 8% 정도 위로.
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.42)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WaypinTheme.brandNavy)
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
