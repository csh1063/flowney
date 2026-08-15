import ProjectDescription
import ProjectDescriptionHelpers

let project = waypinModuleProject(
    moduleName: "AuthFeature",
    bundleIdSuffix: "features.auth",
    dependencies: [
        WaypinModule.models.dependency,
        WaypinModule.designSystem.dependency,
        WaypinModule.apiClient.dependency,
        WaypinModule.addItem.dependency,
        .external(name: "ComposableArchitecture"),
        .external(name: "Supabase"),
        .external(name: "GoogleSignIn"),
        .external(name: "GoogleSignInSwift"),
        .sdk(name: "AuthenticationServices", type: .framework),
    ]
)
