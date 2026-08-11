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
        .external(name: "ComposableArchitecture"),
        .external(name: "GoogleMaps"),
    ]
)
