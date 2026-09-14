import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "DesignSystem",
    bundleIdSuffix: "core.designsystem",
    dependencies: [
        FlowneyModule.models.dependency,
    ]
)
