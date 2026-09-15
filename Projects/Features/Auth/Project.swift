import ProjectDescription
import ProjectDescriptionHelpers

let project = flowneyModuleProject(
    moduleName: "AuthFeature",
    bundleIdSuffix: "features.auth",
    dependencies: [
        FlowneyModule.models.dependency,
        FlowneyModule.designSystem.dependency,
        FlowneyModule.apiClient.dependency,
        .external(name: "ComposableArchitecture"),
        .external(name: "Supabase"),
        .external(name: "GoogleSignIn"),
        .external(name: "GoogleSignInSwift"),
        .sdk(name: "AuthenticationServices", type: .framework),
        .sdk(name: "SafariServices", type: .framework),
    ]
)
