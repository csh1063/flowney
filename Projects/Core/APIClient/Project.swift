import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "APIClient",
    bundleIdSuffix: "core.apiclient",
    dependencies: [
        FlowneyModule.models.dependency,
        .external(name: "ComposableArchitecture"),
        .external(name: "Supabase"),
    ]
)
