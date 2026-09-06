import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Waypin",
    targets: [
        .target(
            name: "Waypin",
            destinations: Constants.destinations,
            product: .app,
            bundleId: Constants.bundleIdPrefix,
            deploymentTargets: Constants.deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLSchemes": ["$(GOOGLE_REVERSED_CLIENT_ID)"],
                        ],
                    ],
                    "LSApplicationQueriesSchemes": ["comgooglemaps"],
                    "NSLocationWhenInUseUsageDescription": "여행 경로와 현재 위치를 지도에 표시하기 위해 위치 정보를 사용합니다.",
                    "GMSApiKey": "$(GOOGLE_MAPS_API_KEY)",
                    "GIDClientID": "$(GOOGLE_IOS_CLIENT_ID)",
                    "SupabaseHost": "$(SUPABASE_HOST)",
                    "SupabaseAnonKey": "$(SUPABASE_ANON_KEY)",
                    "UIAppFonts": [
                        "GothicA1-Regular.ttf",
                        "GothicA1-SemiBold.ttf",
                    ],
                ]
            ),
            sources: ["Sources/**"],
            resources: [
                "Resources/**",
            ],
            entitlements: .file(path: "Waypin.entitlements"),
            dependencies: [
                WaypinModule.root.dependency,
                WaypinModule.designSystem.dependency,
                .external(name: "ComposableArchitecture"),
                .external(name: "GoogleSignIn"),
                .external(name: "GoogleSignInSwift"),
                .external(name: "GoogleMaps"),
                .project(target: "WaypinShareExtension", path: .relativeToRoot("Projects/ShareExtension")),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "DEVELOPMENT_TEAM": .string(Constants.developmentTeam),
                    "CODE_SIGN_STYLE": "Automatic",
                    "OTHER_LDFLAGS": ["-ObjC"],
                ],
                configurations: [
                    .debug(name: .debug, xcconfig: "Config.xcconfig"),
                    .release(name: .release, xcconfig: "Config.xcconfig"),
                ]
            )
        ),
    ]
)
