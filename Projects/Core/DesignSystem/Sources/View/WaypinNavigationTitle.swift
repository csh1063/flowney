import SwiftUI

extension View {
    public func waypinLeadingTitle(_ title: String) -> some View {
        navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(WaypinFont.sectionHeader)
                        .foregroundStyle(WaypinTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
    }
}
