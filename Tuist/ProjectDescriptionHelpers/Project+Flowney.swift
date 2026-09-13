import ProjectDescription

/// Creates a Project.swift for an internal static-framework module (Core or Feature).
/// `bundleIdSuffix` example: "core.models", "features.auth".
public func flowneyModuleProject(
    moduleName: String,
    bundleIdSuffix: String,
    dependencies: [TargetDependency] = [],
    includeTests: Bool = false
) -> Project {
    var targets: [Target] = [
        .target(
            name: moduleName,
            destinations: Constants.destinations,
            product: .staticFramework,
            bundleId: "\(Constants.bundleIdPrefix).\(bundleIdSuffix)",
            deploymentTargets: Constants.deploymentTargets,
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: dependencies
        ),
    ]

    if includeTests {
        targets.append(
            .target(
                name: "\(moduleName)Tests",
                destinations: Constants.destinations,
                product: .unitTests,
                bundleId: "\(Constants.bundleIdPrefix).\(bundleIdSuffix).tests",
                deploymentTargets: Constants.deploymentTargets,
                infoPlist: .default,
                sources: ["Tests/**"],
                dependencies: [.target(name: moduleName)]
            )
        )
    }

    return Project(
        name: moduleName,
        targets: targets
    )
}
