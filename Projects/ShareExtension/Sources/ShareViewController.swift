import DesignSystem
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 구글맵 앱 공유 시트에서 "Waypin에 추가"를 누르면 뜨는 화면.
/// 전체 화면 대신 우리 테마를 쓴 작은 스낵바 하나만 화면 하단에 띄운다 — 공유받은 URL을
/// App Group에 남기고 "저장했습니다"를 잠깐 보여준 뒤 자동으로 닫는다.
/// 실제 처리(장소 해석, 여행/날짜 선택)는 메인 앱의 공유 링크함이 다음 실행 때 담당한다 —
/// 익스텐션 프로세스 경계로 Supabase 로그인 세션을 공유할 필요가 없어짐.
final class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<ShareSnackbarView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        // 전체 화면 흰 배경 대신 투명하게 둬서, 아래 깔린 스낵바만 떠 있는 것처럼 보이게 한다.
        view.backgroundColor = .clear
        showSnackbar(message: "링크를 저장 중입니다...")

        extractSharedURL { [weak self] urlString in
            guard let self else { return }
            if let urlString {
                PendingShareWriter.save(urlString: urlString)
            }
            self.showSnackbar(message: "저장했습니다")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }

    private func showSnackbar(message: String) {
        if let hostingController {
            hostingController.rootView = ShareSnackbarView(message: message)
            return
        }
        let hosting = UIHostingController(rootView: ShareSnackbarView(message: message))
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }

    private func extractSharedURL(completion: @escaping (String?) -> Void) {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let attachments = item.attachments
        else {
            completion(nil)
            return
        }

        // 1) 구글맵 앱이 URL 타입으로 공유한 경우 (가장 흔한 경로)
        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                completion((data as? URL)?.absoluteString)
            }
            return
        }

        // 2) URL이 포함된 일반 텍스트로 공유된 경우 폴백
        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                completion(data as? String)
            }
            return
        }

        completion(nil)
    }
}

/// 화면 하단에 뜨는 작은 스낵바 — 앱 본체의 `WaypinCard`/`WaypinTheme`와 같은 톤으로 맞췄다
/// (이 파일에서 직접 재사용하기엔 카드 컴포넌트가 APIClient/TCA 의존성 없이도 쓸 수 있는
/// DesignSystem 모듈에 있어서, 익스텐션에도 가볍게 추가했다).
private struct ShareSnackbarView: View {
    let message: String

    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(WaypinFont.bodyEmphasis)
                .foregroundStyle(WaypinTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, WaypinSpacing.lg)
                .padding(.vertical, WaypinSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous)
                        .fill(WaypinTheme.surface)
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                )
                .padding(.horizontal, WaypinSpacing.lg)
                .padding(.bottom, WaypinSpacing.xl)
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

/// APIClient 모듈(Supabase/TCA 등 무거운 의존성)을 익스텐션에 끌어오지 않으려고
/// App Group 저장 로직만 최소한으로 복제. Core/APIClient의 `PendingShare`/`PendingShareStore`와
/// 완전히 같은 JSON 형태(키 이름, 필드)를 써야 한다 — 한쪽만 바꾸면 디코딩이 깨진다.
private enum PendingShareWriter {
    private struct PendingShareRecord: Codable {
        var id: UUID
        var urlString: String
        var savedAt: Date
        var hasBeenAdded: Bool
    }

    static func save(urlString: String) {
        guard let defaults = UserDefaults(suiteName: "group.com.baci.waypin") else { return }
        var records: [PendingShareRecord] = []
        if
            let data = defaults.data(forKey: "pendingShares"),
            let decoded = try? JSONDecoder().decode([PendingShareRecord].self, from: data)
        {
            records = decoded
        }
        records.append(PendingShareRecord(id: UUID(), urlString: urlString, savedAt: Date(), hasBeenAdded: false))
        guard let encoded = try? JSONEncoder().encode(records) else { return }
        defaults.set(encoded, forKey: "pendingShares")
        // 메인 앱을 다음에 켰을 때 공유링크함을 자동으로 한 번 열어주기 위한 플래그.
        // Core/APIClient의 `PendingShareAutoOpenFlag`와 같은 키를 쓴다.
        defaults.set(true, forKey: "shouldAutoOpenShareInboxOnNextLaunch")
    }
}
