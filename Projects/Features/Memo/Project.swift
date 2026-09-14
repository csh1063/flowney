import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "Memo",
    bundleIdSuffix: "features.memo",
    dependencies: [
        FlowneyModule.models.dependency,
        FlowneyModule.designSystem.dependency,
        FlowneyModule.apiClient.dependency,
        FlowneyModule.tripEdit.dependency,
        .external(name: "ComposableArchitecture"),
        .sdk(name: "UserNotifications", type: .framework),
    ]
)
