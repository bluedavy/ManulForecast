import SwiftUI

struct DebugControlsView: View {
    @Binding var showDebug: Bool
    @Binding var showWeatherDebug: Bool
    @Binding var tuning: SceneTuning

    var body: some View {
        VStack {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    DebugToolButton(systemName: "cube.transparent", isActive: showDebug) {
                        showDebug.toggle()
                        if showDebug { showWeatherDebug = false }
                    }
                    DebugToolButton(systemName: "cloud.sun.rain.fill", isActive: showWeatherDebug) {
                        showWeatherDebug.toggle()
                        if showWeatherDebug { showDebug = false }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.68), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.08), lineWidth: 0.8)
                )
                .padding(.trailing, 18)
                .padding(.top, 14)
            }
            Spacer()
            if showDebug {
                debugPanel
            }
            if showWeatherDebug {
                weatherPanel
            }
        }
    }

    private var debugPanel: some View {
        VStack {
            Spacer()
            ScrollView(showsIndicators: true) {
                VStack(spacing: 16) {
                    Text("构图与机位控制台").font(.headline).foregroundStyle(.white)
                    sliderRow(label: "Scale", value: $tuning.manulScale, range: 1.0...3.0, step: 0.01, format: "%.2f")
                    sliderRow(label: "RotY °", value: $tuning.manulRotY, range: -30...30, step: 1.0, format: "%.0f")
                    sliderRow(label: "RotX °", value: $tuning.manulRotX, range: -20...20, step: 1.0, format: "%.0f")
                    sliderRow(label: "posX", value: $tuning.posX, range: -0.5...0.5, step: 0.01, format: "%.2f")
                    sliderRow(label: "posY", value: $tuning.posY, range: -1.0...0.5, step: 0.01, format: "%.2f")
                    sliderRow(label: "posZ", value: $tuning.posZ, range: -1.0...1.0, step: 0.01, format: "%.2f")
                    sliderRow(label: "Cam Y", value: $tuning.camPosY, range: -1.0...0.5, step: 0.01, format: "%.2f")
                    sliderRow(label: "TargetY", value: $tuning.camTargetY, range: -1.0...0.5, step: 0.01, format: "%.2f")
                }
                .padding()
            }
            .frame(maxHeight: 450)
            .background(.ultraThinMaterial.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    private var weatherPanel: some View {
        VStack {
            Spacer()
            ScrollView(showsIndicators: true) {
                VStack(spacing: 16) {
                    Text("气象控制台").font(.headline).foregroundStyle(.white)
                    sliderRow(label: "Rain Y", value: $tuning.rainPosY, range: 0.0...10.0, step: 0.5, format: "%.1f")
                    sliderRow(label: "Intensity", value: $tuning.rainIntensity, range: 0.0...1.0, step: 0.05, format: "%.2f")
                    sliderRow(label: "Max BR", value: $tuning.maxBirthRate, range: 1000...50000, step: 1000, format: "%.0f")
                    sliderRow(label: "Max Spd", value: $tuning.maxSpeed, range: 1.0...20.0, step: 1.0, format: "%.0f")
                    sliderRow(label: "Stretch", value: $tuning.maxStretch, range: 0.0...5.0, step: 0.1, format: "%.1f")
                    sliderRow(label: "Size", value: $tuning.maxSize, range: 0.0005...0.008, step: 0.0001, format: "%.4f")
                }
                .padding()
            }
            .frame(maxHeight: 450)
            .background(.ultraThinMaterial.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    private func sliderRow(label: String, value: Binding<Float>, range: ClosedRange<Float>, step: Float = 0.01, format: String = "%.2f") -> some View {
        HStack {
            Text(label).frame(width: 64, alignment: .leading).foregroundStyle(.white)
            Slider(value: value, in: range, step: step.magnitude > 0 ? step : 0.01)
            Text(String(format: format, value.wrappedValue))
                .frame(width: 72, alignment: .trailing)
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }
}

private struct DebugToolButton: View {
    let systemName: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isActive ? .white : .white.opacity(0.78))
                .frame(width: 34, height: 34)
                .background(
                    Group {
                        if isActive {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.12))
                        } else {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.clear)
                        }
                    }
                )
        }
    }
}
