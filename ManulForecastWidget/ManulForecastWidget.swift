import SwiftUI
import WidgetKit

struct ManulWidgetEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let content: WidgetDisplayContent
    let icon: String
    let accent: Color
    let gradient: [Color]
}

struct ManulWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ManulWidgetEntry {
        WidgetWeatherSnapshot.sample(date: .now).entry
    }

    func getSnapshot(in context: Context, completion: @escaping (ManulWidgetEntry) -> Void) {
        completion(WidgetWeatherSnapshot.sample(date: .now).entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ManulWidgetEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()

        let entries = (0..<6).compactMap { offset -> ManulWidgetEntry? in
            guard let date = calendar.date(byAdding: .hour, value: offset * 2, to: now) else {
                return nil
            }
            return WidgetWeatherSnapshot.sample(date: date).entry
        }

        let refreshDate = calendar.date(byAdding: .hour, value: 2, to: now) ?? now.addingTimeInterval(7200)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }
}

struct ManulForecastWidget: Widget {
    let kind = "ManulForecastWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ManulWidgetProvider()) { entry in
            ManulWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "manulforecast://home"))
        }
        .configurationDisplayName("兔狲天气")
        .description("用兔狲状态快速感知当前天气。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ManulWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: ManulWidgetEntry

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        ZStack {
            LinearGradient(colors: entry.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(entry.accent.opacity(0.18))
                .frame(width: isSmall ? 92 : 116, height: isSmall ? 92 : 116)
                .offset(x: isSmall ? 58 : 130, y: -42)
            LinearGradient(
                colors: [.black.opacity(0.03), .black.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer(minLength: isSmall ? 10 : 12)
                hero
                Spacer(minLength: isSmall ? 10 : 12)
                footer
            }
            .padding(isSmall ? 14 : 16)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("兔狲天气")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.56))
                Text(entry.cityName)
                    .font(.system(size: isSmall ? 11 : 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(isSmall ? "S" : "M")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.66))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.white.opacity(0.08), in: Capsule())
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: isSmall ? 10 : 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.content.temperatureText)
                    .font(.system(size: isSmall ? 30 : 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(entry.content.widgetLine)
                    .font(.system(size: isSmall ? 11 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                if !isSmall {
                    Text(entry.content.keyAdvice)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: isSmall ? 34 : 40, height: isSmall ? 34 : 40)
                    Image(systemName: entry.icon)
                        .font(.system(size: isSmall ? 18 : 20, weight: .semibold))
                        .foregroundStyle(entry.accent)
                }

                Text(entry.content.poseLabel)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(isSmall ? 2 : 1)
                    .frame(maxWidth: isSmall ? 54 : 96, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if isSmall {
            VStack(alignment: .leading, spacing: 8) {
                Label(entry.content.weatherLabel, systemImage: "cloud.fill")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.08), in: Capsule())
                Text(entry.content.keyAdvice)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
            }
        } else {
            HStack(spacing: 10) {
                compactMetric(systemName: "cloud.fill", text: entry.content.weatherLabel)
                compactMetric(systemName: "exclamationmark.circle", text: entry.content.keyAdvice)
            }
        }
    }

    private func compactMetric(systemName: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(entry.accent.opacity(0.84))
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.07), in: Capsule())
    }
}

private struct WidgetWeatherSnapshot {
    let content: WidgetDisplayContent
    let icon: String
    let accent: Color
    let gradient: [Color]

    var entry: ManulWidgetEntry {
        ManulWidgetEntry(
            date: .now,
            cityName: content.cityName,
            content: content,
            icon: icon,
            accent: accent,
            gradient: gradient
        )
    }

    static func sample(date: Date) -> WidgetWeatherSnapshot {
        let hour = Calendar.current.component(.hour, from: date)

        if hour >= 21 || hour < 6 {
            return WidgetWeatherSnapshot(
                content: WidgetDisplayContent(
                    cityName: "Shanghai",
                    temperatureText: "12°",
                    weatherLabel: "夜间",
                    poseLabel: "夜里警觉",
                    widgetLine: "夜里别闹。",
                    keyAdvice: "夜里降温"
                ),
                icon: "moon.stars.fill",
                accent: .cyan,
                gradient: [Color(red: 0.09, green: 0.11, blue: 0.18), Color(red: 0.12, green: 0.17, blue: 0.28)]
            )
        }

        switch hour % 4 {
        case 0:
            return WidgetWeatherSnapshot(
                content: WidgetDisplayContent(
                    cityName: "Shanghai",
                    temperatureText: "26°",
                    weatherLabel: "晴天",
                    poseLabel: "眯眼趴着",
                    widgetLine: "太亮了。",
                    keyAdvice: "紫外线偏强"
                ),
                icon: "sun.max.fill",
                accent: .yellow,
                gradient: [Color(red: 0.30, green: 0.58, blue: 0.94), Color(red: 0.62, green: 0.79, blue: 0.98)]
            )
        case 1:
            return WidgetWeatherSnapshot(
                content: WidgetDisplayContent(
                    cityName: "Shanghai",
                    temperatureText: "19°",
                    weatherLabel: "小雨",
                    poseLabel: "缩着避雨",
                    widgetLine: "潮，真烦。",
                    keyAdvice: "出门带伞"
                ),
                icon: "cloud.drizzle.fill",
                accent: .white,
                gradient: [Color(red: 0.29, green: 0.35, blue: 0.45), Color(red: 0.44, green: 0.51, blue: 0.60)]
            )
        case 2:
            return WidgetWeatherSnapshot(
                content: WidgetDisplayContent(
                    cityName: "Shanghai",
                    temperatureText: "15°",
                    weatherLabel: "大雨",
                    poseLabel: "缩着避雨",
                    widgetLine: "别硬出门。",
                    keyAdvice: "尽量减少外出"
                ),
                icon: "cloud.heavyrain.fill",
                accent: .white,
                gradient: [Color(red: 0.13, green: 0.17, blue: 0.24), Color(red: 0.20, green: 0.27, blue: 0.37)]
            )
        default:
            return WidgetWeatherSnapshot(
                content: WidgetDisplayContent(
                    cityName: "Shanghai",
                    temperatureText: "-3°",
                    weatherLabel: "雪天",
                    poseLabel: "安静蓬起",
                    widgetLine: "这天还行。",
                    keyAdvice: "注意保暖和路滑"
                ),
                icon: "cloud.snow.fill",
                accent: Color(red: 0.82, green: 0.9, blue: 1.0),
                gradient: [Color(red: 0.50, green: 0.63, blue: 0.78), Color(red: 0.71, green: 0.81, blue: 0.90)]
            )
        }
    }
}

struct WidgetDisplayContent {
    let cityName: String
    let temperatureText: String
    let weatherLabel: String
    let poseLabel: String
    let widgetLine: String
    let keyAdvice: String
}
