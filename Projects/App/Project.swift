import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Flowney",
    targets: [
        .target(
            name: "Flowney",
            destinations: Constants.destinations,
            product: .app,
            bundleId: Constants.bundleIdPrefix,
            deploymentTargets: Constants.deploymentTargets,
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            resources: [
                "Resources/**",
            ],
            entitlements: .file(path: "Flowney.entitlements"),
            dependencies: [
                FlowneyModule.root.dependency,
                FlowneyModule.designSystem.dependency,
                .external(name: "ComposableArchitecture"),
                .external(name: "GoogleSignIn"),
                .external(name: "GoogleSignInSwift"),
                .external(name: "GoogleMaps"),
                .project(target: "FlowneyShareExtension", path: .relativeToRoot("Projects/ShareExtension")),
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
