import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "TripEdit",
    bundleIdSuffix: "features.tripedit",
    dependencies: [
        FlowneyModule.models.dependency,
        FlowneyModule.designSystem.dependency,
        FlowneyModule.apiClient.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
