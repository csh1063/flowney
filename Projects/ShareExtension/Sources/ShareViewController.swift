import DesignSystem
import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<ShareSnackbarView>?

    override func viewDidLoad() {
        super.viewDidLoad()
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

        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                completion((data as? URL)?.absoluteString)
            }
            return
        }

        if let provider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                completion(data as? String)
            }
            return
        }

        completion(nil)
    }
}

private struct ShareSnackbarView: View {
    let message: String

    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(FlowneyFont.bodyEmphasis)
                .foregroundStyle(FlowneyTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, FlowneySpacing.lg)
                .padding(.vertical, FlowneySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous)
                        .fill(FlowneyTheme.surface)
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                )
                .padding(.horizontal, FlowneySpacing.lg)
                .padding(.bottom, FlowneySpacing.xl)
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

private enum PendingShareWriter {
    private struct PendingShareRecord: Codable {
        var id: UUID
        var urlString: String
        var savedAt: Date
        var hasBeenAdded: Bool
    }

    static func save(urlString: String) {
        guard let defaults = UserDefaults(suiteName: "group.com.baci.flowney") else { return }
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
        defaults.set(true, forKey: "shouldAutoOpenShareInboxOnNextLaunch")
    }
}
