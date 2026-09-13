import SwiftUI

extension View {
    public func flowneyLeadingTitle(_ title: String) -> some View {
        navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(FlowneyFont.sectionHeader)
                        .foregroundStyle(FlowneyTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
    }
}
