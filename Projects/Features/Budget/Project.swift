import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "Budget",
    bundleIdSuffix: "features.budget",
    dependencies: [
        FlowneyModule.models.dependency,
        FlowneyModule.designSystem.dependency,
        FlowneyModule.apiClient.dependency,
        FlowneyModule.tripEdit.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
