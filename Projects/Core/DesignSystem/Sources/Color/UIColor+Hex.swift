import UIKit

extension UIColor {
    public convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString.removeAll { $0 == "#" }

        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)

        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
