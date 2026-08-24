import DesignSystem
import SwiftUI

struct SplashView: View {
    var body: some View {
        GeometryReader { proxy in
            Image("SplashIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
