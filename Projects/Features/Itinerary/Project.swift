import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "Itinerary",
    bundleIdSuffix: "features.itinerary",
    dependencies: [
        WaypinModule.models.dependency,
        WaypinModule.designSystem.dependency,
        WaypinModule.apiClient.dependency,
        WaypinModule.addItem.dependency,
        WaypinModule.tripEdit.dependency,
        .external(name: "ComposableArchitecture"),
        .external(name: "GoogleMaps"),
    ]
)
