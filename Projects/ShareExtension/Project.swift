import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "WaypinShareExtension",
    targets: [
        .target(
            name: "WaypinShareExtension",
            destinations: Constants.destinations,
            product: .appExtension,
            bundleId: "\(Constants.bundleIdPrefix).shareextension",
            deploymentTargets: Constants.deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Waypin에 추가",
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.share-services",
                        "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).ShareViewController",
                        "NSExtensionAttributes": [
                            "NSExtensionActivationRule": [
                                "NSExtensionActivationSupportsWebURLWithMaxCount": 1,
                                "NSExtensionActivationSupportsText": true,
                            ],
                        ],
                    ],
                ]
            ),
            sources: ["Sources/**"],
            entitlements: .file(path: "WaypinShareExtension.entitlements"),
            dependencies: [
                WaypinModule.designSystem.dependency,
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": .string(Constants.developmentTeam),
                    "CODE_SIGN_STYLE": "Automatic",
                ]
            )
        ),
    ]
)
