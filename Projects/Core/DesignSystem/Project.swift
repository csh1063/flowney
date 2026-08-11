import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "DesignSystem",
    bundleIdSuffix: "core.designsystem",
    dependencies: [
        WaypinModule.models.dependency,
    ]
)
