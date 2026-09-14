import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "TripList",
    bundleIdSuffix: "features.triplist",
    dependencies: [
        FlowneyModule.models.dependency,
        FlowneyModule.designSystem.dependency,
        FlowneyModule.apiClient.dependency,
        FlowneyModule.tripEdit.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
