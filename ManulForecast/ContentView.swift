//
//  ContentView.swift
//  ManulForecast
//
//  Created by bixuan on 2026/2/22.
//

import SwiftUI
import RealityKit
import WeatherAssets
import UIKit

// MARK: - ECS 天气黑盒：组件 + 系统

/// 自定义组件：作为暴露给 UI 的“数据插座”
public struct WeatherControl: Component, Codable {
    public var intensity: Float = 0.5
    public var maxBirthRate: Float = 20000
    public var maxSpeed: Float = 3.0
    public var maxStretch: Float = 5.0   // 暴雨时的最大拉丝系数
    public var maxSize: Float = 0.015     // 暴雨时的最大雨滴尺寸
    public var isDirty: Bool = true
    public init() {}
}

/// 底层系统：作为黑盒引擎，负责把 intensity 翻译成复杂的粒子物理参数
public final class WeatherSystem: System {
    private static let query = EntityQuery(where: .has(WeatherControl.self))

    public required init(scene: RealityKit.Scene) {}

    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var control = entity.components[WeatherControl.self] else { continue }

            if !control.isDirty { continue }

            let emitterNode = Self.findParticleEmitter(in: entity)
            if let node = emitterNode, var particleComp = node.components[ParticleEmitterComponent.self] {
                // 1. 基础物理映射 (算出正数的速度绝对值)
                let intensity = control.intensity
                let speedMagnitude = 1.0 + ((control.maxSpeed - 1.0) * intensity)

                particleComp.mainEmitter.birthRate = 500 + ((control.maxBirthRate - 500) * intensity)

                // 将绝对值翻转为负数，以迎合 RCP 让雨水向下落的物理设定
                particleComp.speed = -speedMagnitude

                // 计算生命周期时，必须使用正数绝对值，防止算出负时间导致粒子消失
                particleComp.mainEmitter.lifeSpan = Double(5.0 / speedMagnitude)

                // 2. 视觉形态映射 (解决雪花错觉)
                // 拉丝感和雨滴大小，依然依赖强度
                particleComp.mainEmitter.stretchFactor = (control.maxStretch * intensity)
                let baseSize: Float = 0.003
                particleComp.mainEmitter.size = baseSize + ((control.maxSize - baseSize) * intensity)
                node.components.set(particleComp)

                control.isDirty = false
                entity.components.set(control)
            }
        }
    }

    private static func findParticleEmitter(in entity: Entity) -> Entity? {
        if entity.components.has(ParticleEmitterComponent.self) { return entity }
        for child in entity.children {
            if let found = findParticleEmitter(in: child) { return found }
        }
        return nil
    }
}

// MARK: - Manul 动画辅助：递归查找带骨骼动画的 Entity

@MainActor
private func findAnimatableEntity(in entity: Entity) -> Entity? {
    if !entity.availableAnimations.isEmpty { return entity }
    for child in entity.children {
        if let found = findAnimatableEntity(in: child) { return found }
    }
    return nil
}

/// 递归遍历 Entity，找到第一个非 default 且非 global 的真实动画并返回
@MainActor
private func extractFirstRealAnimation(from entity: Entity) -> AnimationResource? {
    if !entity.availableAnimations.isEmpty {
        for anim in entity.availableAnimations {
            let name = anim.name ?? ""
            if !name.localizedCaseInsensitiveContains("default") && !name.localizedCaseInsensitiveContains("global") {
                return anim
            }
        }
    }
    for child in entity.children {
        if let anim = extractFirstRealAnimation(from: child) { return anim }
    }
    return nil
}

// MARK: - 净化器（需在 MainActor 上运行以访问 Entity 组件/子节点）

@MainActor
private func sanitizeModel(_ entity: Entity) {
    let hasCamera = entity.components[PerspectiveCameraComponent.self] != nil
    let hasSpotLight = entity.components[SpotLightComponent.self] != nil
    let hasDirLight = entity.components[DirectionalLightComponent.self] != nil
    let hasPointLight = entity.components[PointLightComponent.self] != nil

    if hasCamera || hasSpotLight || hasDirLight || hasPointLight {
        entity.removeFromParent()
        return
    }
    for child in Array(entity.children) {
        sanitizeModel(child)
    }
}

// MARK: - ContentView

@MainActor
struct ContentView: View {
    @State private var showDebug = false // 默认隐藏面板
    @State private var showDebugTools = false
    @State private var animations: [String: AnimationResource] = [:]
    @State private var manulEntity: Entity?
    @State private var tuning = SceneTuning()
    @State private var currentWeather: WeatherType = .sunny
    @State private var currentTimeOfDay: TimeOfDay = .noon
    @State private var showWeatherDebug = false
    @State private var rainEntity: Entity?
    @State private var behaviorTask: Task<Void, Never>?
    @State private var speechText: String?
    @State private var speechTask: Task<Void, Never>?

    private var presentation: WeatherPresentation {
        WeatherPresentation(
            cityName: "Shanghai",
            temperatureText: temperatureText,
            currentWeather: currentWeather,
            timeOfDay: currentTimeOfDay
        )
    }

    private var temperatureText: String {
        switch currentWeather {
        case .sunny: return "26°"
        case .lightRain: return "19°"
        case .moderateRain: return "17°"
        case .heavyRain: return "15°"
        case .storm: return "13°"
        case .snowy: return "-3°"
        }
    }

    var body: some View {
        RealityView { content in
                #if os(iOS) || os(macOS)
                content.camera = .virtual
                #endif

                WeatherControl.registerComponent()
                WeatherSystem.registerSystem()

                // 1. 创建容器并直接添加到 content 中，供 update 追踪
                let container = Entity()
                container.name = "ManulContainer"
                content.add(container)

                // 2. 加载骨骼动画版 Manul.usdz，重置变换并植入动画引擎
                do {
                    let baseEntity = try await Entity(named: "Manul", in: weatherAssetsBundle)
                    await MainActor.run {
                        container.addChild(baseEntity)

                        // 2a. 立即输出原始物理尺寸（诊断纳米猫/哥斯拉，relativeTo: self 为模型本地空间）
                        let bounds = baseEntity.visualBounds(relativeTo: baseEntity)
                        print("📏 [尺寸侦测] 狲爷的物理包围盒大小: 宽\(bounds.extents.x), 高\(bounds.extents.y), 深\(bounds.extents.z)")
                        print("📍 [位置侦测] 狲爷的包围盒中心点: \(bounds.center)")

                        // 2b. 重置变换系（模型原始高度 0.6m，保持 1:1 缩放）
                        baseEntity.scale = SIMD3<Float>(1.0, 1.0, 1.0)
                        baseEntity.position = SIMD3<Float>(0, -0.2, -0.5)
                        print("📍 [MainView] 狲爷已加载，当前 Scale: \(baseEntity.scale), Position: \(baseEntity.position)")

                        // 2c. 提取 idle 动画并在 Armature 节点上循环播放（修正 BindPoint）
                        let armature = baseEntity.findEntity(named: "Armature") ?? findAnimatableEntity(in: baseEntity) ?? baseEntity
                        self.manulEntity = baseEntity
                        let animatableEntity = findAnimatableEntity(in: baseEntity) ?? baseEntity
                        if let idle = animatableEntity.availableAnimations.first {
                            self.animations["idle"] = idle
                            armature.playAnimation(idle.repeat(duration: .infinity))
                            print("🚀 [MainView] 正在 Armature 节点上循环播放 idle 呼吸动画")
                        }
                    }

                    // 3. 批量并发加载 6 个动画包，提取灵魂（不加入 content，切勿 content.add）
                    let animationPacks: [(String, String)] = [
                        ("lookright", "Manul_lookright"),
                        ("lookleft", "Manul_lookleft"),
                        ("shiver", "Manul_shiver"),
                        ("tilt", "Manul_tilt"),
                        ("shakewater", "Manul_shakewater"),
                        ("nodsleepy", "Manul_nodsleepy"),
                    ]
                    Task {
                        await withTaskGroup(of: (String, AnimationResource?).self) { group in
                            for (key, assetName) in animationPacks {
                                group.addTask {
                                    do {
                                        let entity = try await Entity(named: assetName, in: weatherAssetsBundle)
                                        let anim = await MainActor.run { extractFirstRealAnimation(from: entity) }
                                        return (key, anim)
                                    } catch {
                                        print("❌ [动画提取] 加载 \(assetName) 失败: \(error)")
                                        return (key, nil)
                                    }
                                }
                            }
                            for await (key, anim) in group {
                                if let anim {
                                    await MainActor.run { self.animations[key] = anim }
                                    print("✅ 提取动作: \(key)")
                                }
                            }
                        }
                        await MainActor.run {
                            print("✅ 所有 6 个动画灵魂包已加载完毕")
                            if let entity = manulEntity { startBehaviorEngine(entity: entity) }
                        }
                    }
                } catch {
                    print("❌ [MainView] Manul 加载失败: \(error)")
                }

                // 5. 加载雨水特效 (独立挂载到世界根节点)
                do {
                    let rain = try await Entity(named: "Rain", in: Bundle.main)
                    await MainActor.run {
                        rain.name = "RainEffect"
                        rain.isEnabled = false
                        rain.position.y = 3.0
                        var weatherControl = WeatherControl()
                        weatherControl.intensity = tuning.rainIntensity
                        weatherControl.maxBirthRate = tuning.maxBirthRate
                        weatherControl.maxSpeed = tuning.maxSpeed
                        weatherControl.maxStretch = tuning.maxStretch
                        weatherControl.maxSize = tuning.maxSize
                        rain.components.set(weatherControl)
                        rainEntity = rain
                        content.add(rain)
                    }
                } catch {
                }

                // 3. 添加相机和灯光
                let cameraEntity = Entity()
                cameraEntity.name = "MainCamera"
                cameraEntity.position = SIMD3<Float>(0, 1.0, 2.5)
                cameraEntity.look(at: [0, 0, 0], from: [0, 1.0, 2.5], relativeTo: nil)
                cameraEntity.components.set(PerspectiveCameraComponent())
                cameraEntity.components.set(DirectionalLightComponent(color: .white, intensity: 1000))
                content.add(cameraEntity)

                let directionalLight = Entity()
                directionalLight.name = "SunLight"
                directionalLight.position = SIMD3<Float>(-2, 2, 2)
                directionalLight.look(at: [0, 0, 0], from: [-2, 2, 2], relativeTo: nil)
                directionalLight.components.set(DirectionalLightComponent(color: .white, intensity: 2000))
                content.add(directionalLight)

            } update: { content in
                // 4. 原生响应：现在容器的状态变化能 100% 触发渲染了！
                if let container = content.entities.first(where: { $0.name == "ManulContainer" }) {
                    container.transform.scale = simd_float3(repeating: tuning.manulScale)
                    let rY = simd_quatf(angle: tuning.manulRotY * .pi / 180, axis: [0, 1, 0])
                    let rX = simd_quatf(angle: tuning.manulRotX * .pi / 180, axis: [1, 0, 0])
                    container.transform.rotation = rY * rX
                    container.transform.translation = SIMD3<Float>(tuning.posX, tuning.posY, tuning.posZ)
                }
                // 动态控制雨水显隐与高度
                if let rain = content.entities.first(where: { $0.name == "RainEffect" }) {
                    rain.isEnabled = currentWeather != .sunny
                    rain.position.y = tuning.rainPosY
                }
                // 动态运镜
                if let camera = content.entities.first(where: { $0.name == "MainCamera" }) {
                    let camPos = SIMD3<Float>(0, tuning.camPosY, 2.5)
                    let target = SIMD3<Float>(0, tuning.camTargetY, 0)
                    camera.position = camPos
                    camera.look(at: target, from: camPos, relativeTo: nil)
                }
                // 1. 动态太阳光：下雨时必须彻底熄灭，防止在湿润材质上打出违和的锐利高光
                if let sunLight = content.entities.first(where: { $0.name == "SunLight" }) {
                    if var comp = sunLight.components[DirectionalLightComponent.self] {
                        // 衰减曲线变陡：只要强度超过 0.5 (中雨)，直射光彻底降为 0
                        let weatherAttenuation = max(0.0, 1.0 - (currentWeather.intensity * 2.0))
                        comp.intensity = 3000 * currentTimeOfDay.intensityMultiplier * weatherAttenuation
                        comp.color = currentTimeOfDay.lightColor
                        sunLight.components.set(comp)

                        let newPos = currentTimeOfDay.lightPosition
                        sunLight.position = newPos
                        sunLight.look(at: [0, 0, 0], from: newPos, relativeTo: nil)
                    }
                }

                // 2. 动态补光灯：雨天充当全局漫反射环境光 (Ambient/Fill Light)
                if let camLight = content.entities.first(where: { $0.name == "MainCamera" }) {
                    if var comp = camLight.components[DirectionalLightComponent.self] {
                        // 暴雨时保留 30% 基础照明，防止死黑
                        let weatherAttenuation = 1.0 - (currentWeather.intensity * 0.7)
                        comp.intensity = 1000 * currentTimeOfDay.intensityMultiplier * weatherAttenuation

                        // 雨天光线失去暖色，变成压抑的冷灰/灰蓝色
                        if currentWeather != .sunny {
                            comp.color = UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1.0)
                        } else {
                            comp.color = .white
                        }
                        camLight.components.set(comp)
                    }
                }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                let profile = BehaviorProfile.profile(for: currentWeather.weatherCondition)
                guard let rootEntity = manulEntity, let anim = animations[profile.tapAction] else {
                    print("⚠️ \(profile.tapAction) 动作未就绪")
                    return
                }
                showSpeech(presentation.snapshot.interactionLines.randomElement() ?? presentation.statusLine)
                if let armature = rootEntity.findEntity(named: "Armature") {
                    armature.playAnimation(anim, transitionDuration: 0.5)
                    print("🎯 成功在 Armature 节点上触发动画")
                } else {
                    print("❌ [错误] 主模型中未找到 Armature 节点")
                }
            }
            .background {
                ZStack {
                    // 1. 底层天空渐变
                    currentTimeOfDay.skyGradient.ignoresSafeArea()

                    // 2. 矢量发光天体 (仅晴天显示)
                    if currentWeather == .sunny {
                        Image(systemName: currentTimeOfDay.celestialSymbol)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundStyle(currentTimeOfDay.celestialColor)
                            // 双层 shadow 制造绝美的物理体积光晕
                            .shadow(color: currentTimeOfDay.celestialColor, radius: 40, x: 0, y: 0)
                            .shadow(color: currentTimeOfDay.celestialColor.opacity(0.6), radius: 15, x: 0, y: 0)
                            .padding(.top, 90)
                            .padding(.horizontal, 50)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: currentTimeOfDay.celestialAlignment)
                    }

                    // 3. 天气乌云遮罩层 (遮挡天空与天体)
                    Color.black.opacity(Double(currentWeather.intensity) * 0.75).ignoresSafeArea()
                }
                .animation(.easeInOut(duration: 1.5), value: currentTimeOfDay)
                .animation(.easeInOut(duration: 1.5), value: currentWeather)
            }
            .overlay {
                ZStack {
                    HomeOverlayView(
                        presentation: presentation,
                        onWeatherTap: cycleWeather,
                        onTimeTap: cycleTimeOfDay,
                        isDebugToggleVisible: isDebugToggleVisible,
                        isDebugToolsPresented: showDebugTools,
                        onDebugToggle: toggleDebugTools,
                        speechText: speechText
                    )
                    if showDebugTools {
                        DebugControlsView(
                            showDebug: $showDebug,
                            showWeatherDebug: $showWeatherDebug,
                            tuning: $tuning
                        )
                    }
                }
            }
        .onChange(of: tuning.rainIntensity) { _, _ in syncWeatherComponent() }
        .onChange(of: tuning.maxBirthRate) { _, _ in syncWeatherComponent() }
        .onChange(of: tuning.maxSpeed) { _, _ in syncWeatherComponent() }
        .onChange(of: tuning.maxStretch) { _, _ in syncWeatherComponent() }
        .onChange(of: tuning.maxSize) { _, _ in syncWeatherComponent() }
    }

    /// 天气驱动行为引擎：无限循环，按天气随机播放动作
    private func startBehaviorEngine(entity: Entity) {
        behaviorTask?.cancel()
        let armature = entity.findEntity(named: "Armature") ?? findAnimatableEntity(in: entity) ?? entity
        behaviorTask = Task { @MainActor in
            while !Task.isCancelled {
                let profile = BehaviorProfile.profile(for: currentWeather.weatherCondition)
                let delay = UInt64.random(in: profile.delayRange)
                do { try await Task.sleep(nanoseconds: delay) } catch { return }
                guard !Task.isCancelled else { return }

                let condition = currentWeather.weatherCondition
                let actionKey = profile.nextAmbientAction()
                guard let anim = animations[actionKey] else { continue }

                armature.playAnimation(anim, transitionDuration: 0.5)
                print("🌤️ [当前天气: \(condition)] 狲爷正在执行: \(actionKey)")
            }
        }
    }

    /// 立即反应：雨天甩水 / 雪天发抖
    private func triggerImmediateReaction(to condition: WeatherCondition) {
        guard let entity = manulEntity else { return }
        let armature = entity.findEntity(named: "Armature") ?? findAnimatableEntity(in: entity) ?? entity
        let profile = BehaviorProfile.profile(for: condition)
        if let immediateAction = profile.immediateAction, let anim = animations[immediateAction] {
            armature.playAnimation(anim, transitionDuration: 0.5)
            print("⚡️ [立即反应] \(condition.rawValue): \(immediateAction)")
        }
        startBehaviorEngine(entity: entity)
    }

    private func syncWeatherComponent() {
        if var control = rainEntity?.components[WeatherControl.self] {
            control.intensity = tuning.rainIntensity
            control.maxBirthRate = tuning.maxBirthRate
            control.maxSpeed = tuning.maxSpeed
            control.maxStretch = tuning.maxStretch
            control.maxSize = tuning.maxSize
            control.isDirty = true
            rainEntity?.components.set(control)
        }
    }

    private func cycleWeather() {
        currentWeather.next()
        tuning.rainIntensity = currentWeather.intensity
        syncWeatherComponent()
        showSpeech(presentation.snapshot.transitionLine)
        let condition = currentWeather.weatherCondition
        if condition == .rainy || condition == .snowy {
            triggerImmediateReaction(to: condition)
        } else if let entity = manulEntity {
            startBehaviorEngine(entity: entity)
        }
    }

    private func cycleTimeOfDay() {
        withAnimation(.easeInOut(duration: 1.5)) {
            currentTimeOfDay.next()
        }
        showSpeech(presentation.snapshot.transitionLine)
    }

    private var isDebugToggleVisible: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private func toggleDebugTools() {
        #if DEBUG
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            showDebugTools.toggle()
            if !showDebugTools {
                showDebug = false
                showWeatherDebug = false
            }
        }
        #endif
    }

    private func showSpeech(_ text: String) {
        speechTask?.cancel()
        withAnimation(.easeInOut(duration: 0.22)) {
            speechText = text
        }

        speechTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                speechText = nil
            }
        }
    }

}

#Preview {
    ContentView()
}
