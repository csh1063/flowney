import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "AddItem",
    bundleIdSuffix: "features.additem",
    dependencies: [
        FlowneyModule.models.dependency,
        FlowneyModule.designSystem.dependency,
        FlowneyModule.apiClient.dependency,
        FlowneyModule.tripEdit.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
