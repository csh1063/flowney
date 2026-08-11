import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "Budget",
    bundleIdSuffix: "features.budget",
    dependencies: [
        WaypinModule.models.dependency,
        WaypinModule.designSystem.dependency,
        WaypinModule.apiClient.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
