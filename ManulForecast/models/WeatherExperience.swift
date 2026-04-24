import SwiftUI
import UIKit

enum WeatherCondition: String, CaseIterable {
    case sunny
    case rainy
    case snowy

    static func actionPool(for condition: WeatherCondition) -> [String] {
        switch condition {
        case .sunny: return ["lookright", "lookleft", "nodsleepy", "tilt"]
        case .rainy: return ["shakewater", "tilt"]
        case .snowy: return ["shiver", "nodsleepy"]
        }
    }
}

enum WeatherType: String, CaseIterable {
    case sunny = "晴天"
    case lightRain = "小雨"
    case moderateRain = "中雨"
    case heavyRain = "大雨"
    case storm = "暴雨"
    case snowy = "雪天"

    var weatherCondition: WeatherCondition {
        switch self {
        case .sunny: return .sunny
        case .lightRain, .moderateRain, .heavyRain, .storm: return .rainy
        case .snowy: return .snowy
        }
    }

    var intensity: Float {
        switch self {
        case .sunny: return 0.0
        case .lightRain: return 0.2
        case .moderateRain: return 0.5
        case .heavyRain: return 0.8
        case .storm: return 1.0
        case .snowy: return 0.4
        }
    }

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .lightRain: return "cloud.drizzle.fill"
        case .moderateRain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .storm: return "cloud.bolt.rain.fill"
        case .snowy: return "cloud.snow.fill"
        }
    }

    mutating func next() {
        let all = Self.allCases
        if let idx = all.firstIndex(of: self) {
            self = all[(idx + 1) % all.count]
        }
    }
}

enum TimeOfDay: String, CaseIterable {
    case morning = "清晨"
    case noon = "正午"
    case evening = "傍晚"
    case night = "深夜"

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .noon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var lightColor: UIColor {
        switch self {
        case .morning: return UIColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1.0)
        case .noon: return .white
        case .evening: return UIColor(red: 1.0, green: 0.55, blue: 0.3, alpha: 1.0)
        case .night: return UIColor(red: 0.4, green: 0.5, blue: 0.8, alpha: 1.0)
        }
    }

    var lightPosition: SIMD3<Float> {
        switch self {
        case .morning: return SIMD3<Float>(1.8, 2.5, -8.0)
        case .noon: return SIMD3<Float>(0.0, 3.5, -8.0)
        case .evening: return SIMD3<Float>(-1.8, 2.5, -8.0)
        case .night: return SIMD3<Float>(-1.5, 3.0, -8.0)
        }
    }

    var intensityMultiplier: Float {
        switch self {
        case .morning: return 0.8
        case .noon: return 1.0
        case .evening: return 0.7
        case .night: return 0.2
        }
    }

    var skyGradient: LinearGradient {
        switch self {
        case .morning:
            return LinearGradient(colors: [Color(red: 0.4, green: 0.6, blue: 0.8), Color(red: 0.9, green: 0.7, blue: 0.5)], startPoint: .top, endPoint: .bottom)
        case .noon:
            return LinearGradient(colors: [Color(red: 0.35, green: 0.65, blue: 0.95), Color(red: 0.65, green: 0.85, blue: 1.0)], startPoint: .top, endPoint: .bottom)
        case .evening:
            return LinearGradient(colors: [Color(red: 0.2, green: 0.3, blue: 0.5), Color(red: 0.8, green: 0.4, blue: 0.2)], startPoint: .top, endPoint: .bottom)
        case .night:
            return LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.15, blue: 0.25)], startPoint: .top, endPoint: .bottom)
        }
    }

    var celestialSymbol: String {
        switch self {
        case .morning, .noon, .evening: return "sun.max.fill"
        case .night: return "moon.fill"
        }
    }

    var celestialColor: Color {
        switch self {
        case .morning: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .noon: return Color(red: 1.0, green: 0.9, blue: 0.6)
        case .evening: return Color(red: 0.9, green: 0.3, blue: 0.1)
        case .night: return Color(red: 0.8, green: 0.9, blue: 1.0)
        }
    }

    var celestialAlignment: Alignment {
        switch self {
        case .morning: return .topTrailing
        case .noon: return .top
        case .evening, .night: return .topLeading
        }
    }

    mutating func next() {
        let all = Self.allCases
        if let idx = all.firstIndex(of: self) {
            self = all[(idx + 1) % all.count]
        }
    }
}

struct WeatherPresentation {
    let cityName: String
    let temperatureText: String
    let currentWeather: WeatherType
    let timeOfDay: TimeOfDay

    var snapshot: WeatherSnapshot {
        WeatherSnapshot(weather: currentWeather, timeOfDay: timeOfDay)
    }

    var statusLine: String {
        snapshot.homeLine
    }

    var keyAdvice: String {
        snapshot.keyAdvice
    }

    var widgetContent: WidgetDisplayContent {
        WidgetDisplayContent(
            cityName: cityName,
            temperatureText: temperatureText,
            weatherLabel: currentWeather.rawValue,
            poseLabel: snapshot.pose.rawValue,
            widgetLine: snapshot.widgetLine,
            keyAdvice: snapshot.keyAdvice
        )
    }

    var homeContent: HomeDisplayContent {
        HomeDisplayContent(
            cityName: cityName,
            temperatureText: temperatureText,
            contextLine: "\(timeLabel) · \(currentWeather.rawValue)",
            poseLabel: snapshot.pose.rawValue,
            statusLine: snapshot.homeLine,
            keyAdvice: snapshot.keyAdvice,
            detailLine: snapshot.detailLine,
            trendHint: snapshot.trendHint
        )
    }

    var timeLabel: String {
        switch timeOfDay {
        case .morning: return "清晨"
        case .noon: return "白天"
        case .evening: return "傍晚"
        case .night: return "夜里"
        }
    }
}

struct HomeDisplayContent {
    let cityName: String
    let temperatureText: String
    let contextLine: String
    let poseLabel: String
    let statusLine: String
    let keyAdvice: String
    let detailLine: String
    let trendHint: String
}

struct WidgetDisplayContent {
    let cityName: String
    let temperatureText: String
    let weatherLabel: String
    let poseLabel: String
    let widgetLine: String
    let keyAdvice: String
}

struct WeatherSnapshot {
    enum ManulPose: String {
        case squintingRest = "眯眼趴着"
        case flatWatch = "无聊观察"
        case curledRain = "缩着避雨"
        case calmSnow = "安静蓬起"
        case nightWatch = "夜里警觉"
    }

    let weather: WeatherType
    let timeOfDay: TimeOfDay

    var pose: ManulPose {
        if timeOfDay == .night {
            return .nightWatch
        }

        switch weather {
        case .sunny:
            return .squintingRest
        case .lightRain, .moderateRain, .heavyRain, .storm:
            return .curledRain
        case .snowy:
            return .calmSnow
        }
    }

    var homeLine: String {
        if timeOfDay == .night {
            return "天黑了，安静点挺好。"
        }

        switch weather {
        case .sunny: return "亮成这样，谁爱出门谁出门。"
        case .lightRain, .moderateRain: return "下得不算狠，烦是一点没少。"
        case .heavyRain, .storm: return "这种天还想体面出门？"
        case .snowy: return "终于像点样子了。"
        }
    }

    var widgetLine: String {
        if timeOfDay == .night {
            return "夜里别闹。"
        }

        switch weather {
        case .sunny: return "太亮了。"
        case .lightRain, .moderateRain: return "潮，真烦。"
        case .heavyRain, .storm: return "别硬出门。"
        case .snowy: return "这天还行。"
        }
    }

    var keyAdvice: String {
        if timeOfDay == .night {
            return "夜里降温"
        }

        switch weather {
        case .sunny: return "紫外线偏强"
        case .lightRain, .moderateRain: return "出门带伞"
        case .heavyRain, .storm: return "尽量减少外出"
        case .snowy: return "注意保暖和路滑"
        }
    }

    var detailLine: String {
        if timeOfDay == .night {
            return "当前偏凉，夜里更适合安静待着。"
        }

        switch weather {
        case .sunny: return "当前晴朗偏晒，体感会更热一点。"
        case .lightRain: return "当前小雨偏潮，晚些时候还会断续落雨。"
        case .moderateRain: return "当前中雨，体感偏湿冷，出门最好备伞。"
        case .heavyRain, .storm: return "当前雨势偏强，今天更适合减少外出。"
        case .snowy: return "当前有雪，空气冷而安静，注意保暖和路滑。"
        }
    }

    var trendHint: String {
        if timeOfDay == .night {
            return "明早再看"
        }

        switch weather {
        case .sunny: return "晚点会柔和些"
        case .lightRain, .moderateRain: return "稍后还会下"
        case .heavyRain, .storm: return "今晚仍有雨"
        case .snowy: return "夜里会更冷"
        }
    }

    var interactionLines: [String] {
        if timeOfDay == .night {
            return ["夜里安静点。", "都这时候了，还不休息？"]
        }

        switch weather {
        case .sunny:
            return ["亮成这样，谁爱出门谁出门。", "晒得眼都懒得睁。"]
        case .lightRain, .moderateRain:
            return ["下得不算狠，烦是一点没少。", "潮成这样，还想出门？"]
        case .heavyRain, .storm:
            return ["这种天还想体面出门？", "别硬撑了，今天就在屋里待着。"]
        case .snowy:
            return ["终于像点样子了。", "冷是冷，至少比闷雨强。"]
        }
    }

    var transitionLine: String {
        interactionLines.first ?? homeLine
    }

    var widgetAccent: Color {
        if timeOfDay == .night {
            return .cyan
        }

        switch weather {
        case .sunny: return .yellow
        case .lightRain, .moderateRain, .heavyRain, .storm: return .white
        case .snowy: return Color(red: 0.82, green: 0.9, blue: 1.0)
        }
    }
}
