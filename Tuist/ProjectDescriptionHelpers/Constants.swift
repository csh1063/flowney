import ProjectDescription

public enum Constants {
    public static let bundleIdPrefix = "com.baci.waypin"
    public static let deploymentTargets: DeploymentTargets = .iOS("17.2")
    public static let destinations: Destinations = .iOS
    /// 실기기 코드사이닝용 Apple Developer 팀 ID — `tuist generate`가 프로젝트를 새로
    /// 만들 때마다 Xcode Signing & Capabilities에서 매번 다시 고를 필요 없게 여기 고정해둔다.
    public static let developmentTeam = "6P4X6KH3P8"
}

/// Cross-project target dependencies (each module lives in its own Project.swift,
/// so references must go through `.project(target:path:)`, not `.target(name:)`).
public enum WaypinModule {
    case models
    case apiClient
    case designSystem
    case auth
    case tripList
    case tripEdit
    case itinerary
    case addItem
    case budget
    case root

    public var targetName: String {
        switch self {
        case .models: return "Models"
        case .apiClient: return "APIClient"
        case .designSystem: return "DesignSystem"
        case .auth: return "AuthFeature"
        case .tripList: return "TripList"
        case .tripEdit: return "TripEdit"
        case .itinerary: return "Itinerary"
        case .addItem: return "AddItem"
        case .budget: return "Budget"
        case .root: return "Root"
        }
    }

    public var path: Path {
        switch self {
        case .models: return .relativeToRoot("Projects/Core/Models")
        case .apiClient: return .relativeToRoot("Projects/Core/APIClient")
        case .designSystem: return .relativeToRoot("Projects/Core/DesignSystem")
        case .auth: return .relativeToRoot("Projects/Features/Auth")
        case .tripList: return .relativeToRoot("Projects/Features/TripList")
        case .tripEdit: return .relativeToRoot("Projects/Features/TripEdit")
        case .itinerary: return .relativeToRoot("Projects/Features/Itinerary")
        case .addItem: return .relativeToRoot("Projects/Features/AddItem")
        case .budget: return .relativeToRoot("Projects/Features/Budget")
        case .root: return .relativeToRoot("Projects/Features/Root")
        }
    }

    public var dependency: TargetDependency {
        .project(target: targetName, path: path)
    }
}
