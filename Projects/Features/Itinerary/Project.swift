import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "Itinerary",
    bundleIdSuffix: "features.itinerary",
    dependencies: [
        FlowneyModule.models.dependency,
        FlowneyModule.designSystem.dependency,
        FlowneyModule.apiClient.dependency,
        FlowneyModule.addItem.dependency,
        FlowneyModule.tripEdit.dependency,
        .external(name: "ComposableArchitecture"),
        .external(name: "GoogleMaps"),
    ]
)
