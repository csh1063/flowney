import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "TripList",
    bundleIdSuffix: "features.triplist",
    dependencies: [
        WaypinModule.models.dependency,
        WaypinModule.designSystem.dependency,
        WaypinModule.apiClient.dependency,
        WaypinModule.tripEdit.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
