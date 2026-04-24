import SwiftUI

struct HomeOverlayView: View {
    let presentation: WeatherPresentation
    let onWeatherTap: () -> Void
    let onTimeTap: () -> Void
    let isDebugToggleVisible: Bool
    let isDebugToolsPresented: Bool
    let onDebugToggle: () -> Void
    let speechText: String?

    private var content: HomeDisplayContent { presentation.homeContent }

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                presentation: presentation,
                content: content,
                onWeatherTap: onWeatherTap,
                onTimeTap: onTimeTap,
                isDebugToggleVisible: isDebugToggleVisible,
                isDebugToolsPresented: isDebugToolsPresented,
                onDebugToggle: onDebugToggle
            )
            .padding(.horizontal, 18)
            .padding(.top, 14)

            Spacer()

            if let speechText, !speechText.isEmpty {
                HStack {
                    SpeechBubble(text: speechText)
                        .frame(maxWidth: 270, alignment: .leading)
                    Spacer()
                }
                .padding(.leading, 78)
                .padding(.trailing, 92)
                .padding(.bottom, 176)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottomTrailing)))
            }

            BottomSummaryBar(presentation: presentation)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
        }
        .animation(.easeInOut(duration: 0.25), value: speechText)
    }
}

private struct HeaderBar: View {
    let presentation: WeatherPresentation
    let content: HomeDisplayContent
    let onWeatherTap: () -> Void
    let onTimeTap: () -> Void
    let isDebugToggleVisible: Bool
    let isDebugToolsPresented: Bool
    let onDebugToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(content.cityName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.96))
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(content.contextLine)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.68))
            }

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                HeaderActionButton(
                    title: "切天气",
                    systemName: presentation.currentWeather.icon,
                    tint: presentation.currentWeather == .sunny ? .yellow : .white,
                    action: onWeatherTap
                )
                HeaderActionButton(
                    title: "切时间",
                    systemName: presentation.timeOfDay.icon,
                    tint: presentation.timeOfDay == .night ? .cyan : .orange,
                    action: onTimeTap
                )
                if isDebugToggleVisible {
                    DebugEntryButton(isActive: isDebugToolsPresented, action: onDebugToggle)
                }
            }
        }
    }
}

private struct BottomSummaryBar: View {
    let presentation: WeatherPresentation

    private var content: HomeDisplayContent { presentation.homeContent }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(content.temperatureText)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 3) {
                    Text(content.statusLine)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                    Text(content.detailLine)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                }
            }

            HStack(spacing: 8) {
                CompactChip(text: content.poseLabel, systemName: "pawprint.fill", tint: presentation.snapshot.widgetAccent)
                CompactChip(text: content.keyAdvice, systemName: "exclamationmark.circle.fill", tint: .white)
                CompactChip(text: content.trendHint, systemName: "clock.fill", tint: .white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.70), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 0.8)
        )
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(.ultraThinMaterial.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 0.8)
                )

            TriangleTail()
                .fill(.white.opacity(0.18))
                .frame(width: 18, height: 12)
                .rotationEffect(.degrees(10))
                .offset(x: -26, y: -2)
        }
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

private struct TriangleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CompactChip: View {
    let text: String
    let systemName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.white.opacity(0.07), in: Capsule())
    }
}

private struct HeaderActionButton: View {
    let title: String
    let systemName: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 11)
            .frame(height: 36)
            .background(.ultraThinMaterial.opacity(0.7), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.08), lineWidth: 0.8)
            )
        }
    }
}

private struct DebugEntryButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "ladybug.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isActive ? .yellow : .white.opacity(0.9))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial.opacity(0.7), in: Circle())
                .overlay(
                    Circle()
                        .stroke(isActive ? .yellow.opacity(0.35) : .white.opacity(0.08), lineWidth: 0.8)
                )
        }
    }
}
