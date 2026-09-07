import Models
import SwiftUI

private struct WaypinLifecycleLog: ViewModifier {
    let name: String
    let category: WaypinLogCategory

    func body(content: Content) -> some View {
        content
            .onAppear { WaypinLog.debug("\(name) onAppear", category: category) }
            .onDisappear { WaypinLog.debug("\(name) onDisappear", category: category) }
    }
}

extension View {
    public func waypinLifecycleLog(category: WaypinLogCategory = .app, file: String = #fileID) -> some View {
        let fileName = file.split(separator: "/").last.map(String.init) ?? file
        let screenName = fileName.hasSuffix(".swift") ? String(fileName.dropLast(6)) : fileName
        return modifier(WaypinLifecycleLog(name: screenName, category: category))
    }
}
