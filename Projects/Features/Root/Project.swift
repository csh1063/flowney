import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "Root",
    bundleIdSuffix: "features.root",
    dependencies: [
        FlowneyModule.models.dependency,
        FlowneyModule.designSystem.dependency,
        FlowneyModule.apiClient.dependency,
        FlowneyModule.auth.dependency,
        FlowneyModule.tripList.dependency,
        FlowneyModule.tripEdit.dependency,
        FlowneyModule.itinerary.dependency,
        FlowneyModule.budget.dependency,
        FlowneyModule.memo.dependency,
        .external(name: "ComposableArchitecture"),
    ]
)
