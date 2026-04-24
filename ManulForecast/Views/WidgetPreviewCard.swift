import SwiftUI

struct WidgetPreviewStrip: View {
    let presentation: WeatherPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("桌面组件")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.94))
                    Text("桌面上先看到兔狲，再决定要不要点进来。")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer(minLength: 12)
                Label("Preview", systemImage: "square.grid.2x2")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.66))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.07), in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    WidgetPreviewCard(size: .small, presentation: presentation)
                    WidgetPreviewCard(size: .medium, presentation: presentation)
                }
                .padding(.horizontal, 1)
            }
            .scrollClipDisabled()
        }
        .padding(18)
        .background(sectionBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var sectionBackground: some ShapeStyle {
        .ultraThinMaterial.opacity(0.92)
    }
}

struct WidgetPreviewCard: View {
    enum Size {
        case small
        case medium
    }

    private struct Layout {
        let width: CGFloat
        let height: CGFloat
        let padding: CGFloat
        let cornerRadius: CGFloat
        let temperatureSize: CGFloat
        let lineSize: CGFloat
        let headerSize: CGFloat
        let metaSize: CGFloat
        let iconSize: CGFloat
        let ornamentSize: CGFloat

        static func metrics(for size: Size) -> Layout {
            switch size {
            case .small:
                return Layout(
                    width: 158,
                    height: 158,
                    padding: 14,
                    cornerRadius: 28,
                    temperatureSize: 31,
                    lineSize: 11,
                    headerSize: 10,
                    metaSize: 10,
                    iconSize: 18,
                    ornamentSize: 84
                )
            case .medium:
                return Layout(
                    width: 329,
                    height: 158,
                    padding: 16,
                    cornerRadius: 28,
                    temperatureSize: 36,
                    lineSize: 13,
                    headerSize: 10,
                    metaSize: 11,
                    iconSize: 20,
                    ornamentSize: 108
                )
            }
        }
    }

    let size: Size
    let presentation: WeatherPresentation

    private var snapshot: WeatherSnapshot { presentation.snapshot }
    private var displayContent: WidgetDisplayContent { presentation.widgetContent }
    private var isSmall: Bool { size == .small }
    private var layout: Layout { .metrics(for: size) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundView
            content
        }
        .frame(width: layout.width, height: layout.height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: isSmall ? 10 : 12)

            hero

            Spacer(minLength: isSmall ? 10 : 12)

            footer
        }
        .padding(layout.padding)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("兔狲天气")
                    .font(.system(size: layout.headerSize, weight: .bold, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(.white.opacity(0.54))
                Text(displayContent.cityName)
                    .font(.system(size: layout.lineSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(isSmall ? "S" : "M")
                .font(.system(size: layout.metaSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.white.opacity(0.08), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.08), lineWidth: 0.6)
                )
                .accessibilityLabel(isSmall ? "Small Widget" : "Medium Widget")
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: isSmall ? 10 : 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayContent.temperatureText)
                    .font(.system(size: layout.temperatureSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(displayContent.widgetLine)
                    .font(.system(size: layout.lineSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                if !isSmall {
                    Text(displayContent.keyAdvice)
                        .font(.system(size: layout.metaSize, weight: .medium, design: .rounded))
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
                    Image(systemName: presentation.currentWeather.icon)
                        .font(.system(size: layout.iconSize, weight: .semibold))
                        .foregroundStyle(snapshot.widgetAccent)
                }

                Text(displayContent.poseLabel)
                    .font(.system(size: layout.metaSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
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
                widgetTag(text: displayContent.weatherLabel, systemName: "cloud.fill")
                Text(displayContent.keyAdvice)
                    .font(.system(size: layout.metaSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }
        } else {
            HStack(spacing: 10) {
                compactMetric(systemName: "cloud.fill", text: displayContent.weatherLabel)
                compactMetric(systemName: "exclamationmark.circle", text: displayContent.keyAdvice)
                compactMetric(systemName: presentation.timeOfDay.icon, text: presentation.timeLabel)
            }
        }
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(snapshot.widgetAccent.opacity(0.16))
                .frame(width: layout.ornamentSize, height: layout.ornamentSize)
                .offset(x: isSmall ? 52 : 108, y: -38)
            LinearGradient(
                colors: [.black.opacity(0.02), .black.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous)
                .fill(.white.opacity(0.03))
        }
    }

    private func compactMetric(systemName: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: layout.metaSize, weight: .semibold))
                .foregroundStyle(snapshot.widgetAccent.opacity(systemName == presentation.timeOfDay.icon ? 0.92 : 0.78))
            Text(text)
                .font(.system(size: layout.metaSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.07), in: Capsule())
    }

    private func widgetTag(text: String, systemName: String) -> some View {
        Label(text, systemImage: systemName)
            .font(.system(size: layout.metaSize, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.white.opacity(0.07), in: Capsule())
    }

    private var gradientColors: [Color] {
        if presentation.timeOfDay == .night {
            return [Color(red: 0.09, green: 0.11, blue: 0.18), Color(red: 0.12, green: 0.17, blue: 0.28)]
        }

        switch presentation.currentWeather {
        case .sunny:
            return [Color(red: 0.30, green: 0.58, blue: 0.94), Color(red: 0.62, green: 0.79, blue: 0.98)]
        case .lightRain, .moderateRain:
            return [Color(red: 0.29, green: 0.35, blue: 0.45), Color(red: 0.44, green: 0.51, blue: 0.60)]
        case .heavyRain, .storm:
            return [Color(red: 0.13, green: 0.17, blue: 0.24), Color(red: 0.20, green: 0.27, blue: 0.37)]
        case .snowy:
            return [Color(red: 0.50, green: 0.63, blue: 0.78), Color(red: 0.71, green: 0.81, blue: 0.90)]
        }
    }
}
