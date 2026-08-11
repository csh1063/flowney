import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "TripEdit",
    bundleIdSuffix: "features.tripedit",
    dependencies: [
        WaypinModule.models.dependency,
        WaypinModule.designSystem.dependency,
        WaypinModule.apiClient.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
