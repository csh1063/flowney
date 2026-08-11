import UIKit
import UniformTypeIdentifiers

/// 구글맵 앱 공유 시트에서 "Waypin에 추가"를 누르면 뜨는 화면.
/// 일부러 아주 단순하게 만들었다: 공유받은 URL을 App Group에 남기고 바로 닫는다.
/// 실제 처리(장소 해석, 여행/날짜 선택)는 메인 앱이 다음 실행 때 담당한다 —
/// 익스텐션 프로세스 경계로 Supabase 로그인 세션을 공유할 필요가 없어짐.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpLoadingUI()

        extractSharedURL { [weak self] urlString in
            guard let self else { return }
            if let urlString {
                PendingShareWriter.save(urlString: urlString)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }

    private func setUpLoadingUI() {
        let label = UILabel()
        label.text = "Waypin에 추가하는 중…"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        view.addSubview(label)
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -16),
        ])
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

/// APIClient 모듈(Supabase/TCA 등 무거운 의존성)을 익스텐션에 끌어오지 않으려고
/// App Group 저장 로직만 최소한으로 복제. Core/APIClient의 PendingShareStore.save와
/// 같은 키를 쓴다 (group ID/키 이름 바꾸면 양쪽 다 맞춰야 함).
private enum PendingShareWriter {
    static func save(urlString: String) {
        guard let defaults = UserDefaults(suiteName: "group.com.baci.waypin") else { return }
        defaults.set(urlString, forKey: "pendingSharedURL")
        defaults.set(Date().timeIntervalSince1970, forKey: "pendingSharedAt")
    }
}
