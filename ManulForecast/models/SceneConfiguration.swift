import Foundation

struct SceneTuning {
    var manulScale: Float = 1.84
    var manulRotY: Float = 4.0
    var manulRotX: Float = 0.0
    var posX: Float = 0.07
    var posY: Float = -0.34
    var posZ: Float = 0.0
    var camPosY: Float = -0.29
    var camTargetY: Float = -0.12
    var rainPosY: Float = 3.0
    var rainIntensity: Float = 0.0
    var maxBirthRate: Float = 10000
    var maxSpeed: Float = 10.0
    var maxStretch: Float = 1.7
    var maxSize: Float = 0.002
}

struct BehaviorProfile {
    let delayRange: ClosedRange<UInt64>
    let primaryAction: String
    let secondaryActions: [String]
    let tapAction: String
    let immediateAction: String?

    static func profile(for condition: WeatherCondition) -> BehaviorProfile {
        switch condition {
        case .sunny:
            return BehaviorProfile(
                delayRange: 5_000_000_000...9_000_000_000,
                primaryAction: "lookright",
                secondaryActions: ["lookleft", "nodsleepy", "tilt"],
                tapAction: "lookright",
                immediateAction: nil
            )
        case .rainy:
            return BehaviorProfile(
                delayRange: 4_000_000_000...7_000_000_000,
                primaryAction: "shakewater",
                secondaryActions: ["tilt"],
                tapAction: "shakewater",
                immediateAction: "shakewater"
            )
        case .snowy:
            return BehaviorProfile(
                delayRange: 6_000_000_000...10_000_000_000,
                primaryAction: "nodsleepy",
                secondaryActions: ["shiver"],
                tapAction: "nodsleepy",
                immediateAction: "shiver"
            )
        }
    }

    func nextAmbientAction() -> String {
        let weightedActions = [primaryAction, primaryAction] + secondaryActions
        return weightedActions.randomElement() ?? primaryAction
    }
}
