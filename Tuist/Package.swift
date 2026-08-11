// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            // TCA ships as a staticFramework by default, which triggers a known
            // Tuist/TCA incompatibility (duplicated-product-name lint + runtime
            // Perception/Observation branch confusion). Forcing a dynamic
            // framework avoids that class of issue.
            "ComposableArchitecture": .framework,
            // TCA의 하위 의존성들도 staticFramework 상태로 두면 TCA 프레임워크 안과
            // 앱 타겟 양쪽에 중복 링크돼서 "may introduce unwanted side effects" 경고가 뜬다.
            // 전부 동적 프레임워크로 맞춰서 한 번만 링크되게 함.
            "Clocks": .framework,
            "ConcurrencyExtras": .framework,
            "IssueReporting": .framework,
            "XCTestDynamicOverlay": .framework,
        ],
        baseSettings: .settings(base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "17.2",
        ]),
        targetSettings: [
            // Under this toolchain (Xcode 26.3 / Swift 6.2.4), TCA 1.26.1's
            // Binding+Observation.swift fails to compile at ANY deployment target:
            // <17 hits an unguarded iOS-17-only UIKit API (NavigationStackControllerUIKit.swift),
            // >=17 hits a spurious "'_StoreBindable_Perception' is unavailable" error even
            // though the reference sits inside its own matching `@available(..., obsoleted: 17)`
            // guard — a compiler availability-pruning bug, not a real availability violation.
            // Disabling availability checking for just this target sidesteps it without
            // weakening availability enforcement anywhere in our own code.
            "ComposableArchitecture": .settings(base: [
                "IPHONEOS_DEPLOYMENT_TARGET": "17.2",
                "OTHER_SWIFT_FLAGS": "$(inherited) -Xfrontend -disable-availability-checking",
            ]),
        ]
    )
#endif

let package = Package(
    name: "Waypin",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        // TCA's macro target (ComposableArchitectureMacros) fails to compile against
        // swift-syntax 600.0.1 under this toolchain (GenericArgumentSyntax.Argument was
        // removed in that exact release; TCA's `#if canImport(SwiftSyntax601)` guard
        // assumes the break landed at 601, not 600). Pinning to 601.0.1 lands on the
        // branch TCA's source actually expects.
        .package(url: "https://github.com/swiftlang/swift-syntax", exact: "601.0.1"),
        // Confirmed: this is also what the resolver lands on naturally given the swift-syntax
        // pin above (removing this pin doesn't change the resolved version) — pinned explicitly
        // just so a future upstream change can't silently shift it.
        .package(url: "https://github.com/pointfreeco/swift-perception", exact: "1.6.0"),
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.24.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "8.0.0"),
        .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "9.0.0"),
    ]
)
