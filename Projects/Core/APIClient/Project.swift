import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "APIClient",
    bundleIdSuffix: "core.apiclient",
    dependencies: [
        WaypinModule.models.dependency,
        .external(name: "ComposableArchitecture"),
        .external(name: "Supabase"),
    ]
)
