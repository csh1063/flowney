import Models
import SwiftUI

private struct FlowneyLifecycleLog: ViewModifier {
    let name: String
    let category: FlowneyLogCategory

    func body(content: Content) -> some View {
        content
            .onAppear { FlowneyLog.debug("\(name) onAppear", category: category) }
            .onDisappear { FlowneyLog.debug("\(name) onDisappear", category: category) }
    }
}

extension View {
    public func flowneyLifecycleLog(category: FlowneyLogCategory = .app, file: String = #fileID) -> some View {
        let fileName = file.split(separator: "/").last.map(String.init) ?? file
        let screenName = fileName.hasSuffix(".swift") ? String(fileName.dropLast(6)) : fileName
        return modifier(FlowneyLifecycleLog(name: screenName, category: category))
    }
}
