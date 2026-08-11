import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "Root",
    bundleIdSuffix: "features.root",
    dependencies: [
        WaypinModule.models.dependency,
        WaypinModule.designSystem.dependency,
        WaypinModule.apiClient.dependency,
        WaypinModule.auth.dependency,
        WaypinModule.tripList.dependency,
        WaypinModule.tripEdit.dependency,
        WaypinModule.itinerary.dependency,
        WaypinModule.budget.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
