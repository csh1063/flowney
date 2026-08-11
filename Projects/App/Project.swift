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
                ]
            ),
            sources: ["Sources/**"],
            resources: [
                "Resources/**",
            ],
            entitlements: .file(path: "Waypin.entitlements"),
            dependencies: [
                WaypinModule.root.dependency,
                .external(name: "ComposableArchitecture"),
                .external(name: "GoogleSignIn"),
                .external(name: "GoogleSignInSwift"),
                .external(name: "GoogleMaps"),
                // 실기기 테스트 위해 임시로 뺌: WaypinShareExtension이 미등록 App Group
                // 권한(group.com.baci.waypin)을 요구해서 실기기 코드사이닝을 깨뜨릴 수 있음.
                // 실제 App Group을 Apple Developer 계정에 등록한 뒤 다시 추가할 것.
                // .project(target: "WaypinShareExtension", path: .relativeToRoot("Projects/ShareExtension")),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "DEVELOPMENT_TEAM": .string(Constants.developmentTeam),
                    "CODE_SIGN_STYLE": "Automatic",
                    // DEBUG_DIAGNOSTIC: navigationDestination(for:) 렌더링 실패가
                    // ENABLE_DEBUG_DYLIB=NO 때문인지 테스트하기 위해 잠시 제거.
                ],
                configurations: [
                    .debug(name: .debug, xcconfig: "Config.xcconfig"),
                    .release(name: .release, xcconfig: "Config.xcconfig"),
                ]
            )
        ),
    ]
)
