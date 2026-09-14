import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "FlowneyShareExtension",
    targets: [
        .target(
            name: "FlowneyShareExtension",
            destinations: Constants.destinations,
            product: .appExtension,
            bundleId: "\(Constants.bundleIdPrefix).shareextension",
            deploymentTargets: Constants.deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Flowney에 추가",
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
            entitlements: .file(path: "FlowneyShareExtension.entitlements"),
            dependencies: [
                FlowneyModule.designSystem.dependency,
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
