import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "AddItem",
    bundleIdSuffix: "features.additem",
    dependencies: [
        WaypinModule.models.dependency,
        WaypinModule.designSystem.dependency,
        WaypinModule.apiClient.dependency,
        WaypinModule.tripEdit.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
