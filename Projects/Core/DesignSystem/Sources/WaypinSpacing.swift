import CoreGraphics

/// 화면마다 따로 정하던 여백 숫자(8, 10, 12, 14...)를 4pt 그리드 기준 스케일로 정리.
public enum WaypinSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

/// 화면마다 따로 정하던 코너 radius(8, 10, 12...)를 정리.
public enum WaypinRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    /// 알약(필) 모양 — 항상 세로 길이의 절반 이상이라 999면 어떤 높이에서도 완전히 둥글다.
    public static let pill: CGFloat = 999
}
