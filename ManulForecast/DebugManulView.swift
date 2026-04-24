//
//  DebugManulView.swift
//  ManulForecast
//
//  智能动画探针与播放器 (Smart Animation Probe & Player)
//

import SwiftUI
import RealityKit
import WeatherAssets

struct DebugManulView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RealityView { content in
                print("\n--------- 🔍 开始检测 Manul.usdz ---------")

                do {
                    // 1. 异步加载 Manul 实体
                    let rootEntity = try await Entity(named: "Manul", in: weatherAssetsBundle)
                    await MainActor.run {
                        content.add(rootEntity)

                        // 💡 主光源 (Key Light)
                        let mainLight = Entity()
                        let mainLightComp = DirectionalLightComponent(color: .white, intensity: 3000)
                        mainLight.components.set(mainLightComp)
                        mainLight.look(at: .zero, from: [1, 2, 2], relativeTo: nil)
                        content.add(mainLight)

                        // 💡 辅助补光 (Fill Light - 防止阴影死黑)
                        let fillLight = Entity()
                        let fillLightComp = DirectionalLightComponent(color: .white, intensity: 1000)
                        fillLight.components.set(fillLightComp)
                        fillLight.look(at: .zero, from: [-1, 0.5, -2], relativeTo: nil)
                        content.add(fillLight)
                    }
                    print("✅ 模型加载成功: Manul")

                    // 2. 递归查找并播放动画
                    await MainActor.run {
                        var foundValidAnimation = false

                        func exploreAndPlay(entity: Entity, depth: Int) {
                            let indent = String(repeating: "  ", count: depth)

                            if !entity.availableAnimations.isEmpty {
                                print("\(indent)🟢 节点[\(entity.name)] 包含 \(entity.availableAnimations.count) 个动画")
                                for anim in entity.availableAnimations {
                                    let animName = anim.name ?? "Unnamed"
                                    print("\(indent)   🎬 发现动画: \(animName)")

                                    // 3. 过滤系统空动画，捕捉真实动作
                                    let isSystemAnim = animName.localizedCaseInsensitiveContains("default")
                                        || animName.localizedCaseInsensitiveContains("global")

                                    if !isSystemAnim && !foundValidAnimation {
                                        print("\(indent)   🚀 正在强制播放动画: \(animName)")
                                        entity.playAnimation(anim.repeat(duration: .infinity))
                                        foundValidAnimation = true
                                    }
                                }
                            }

                            // 继续深层遍历
                            for child in entity.children {
                                exploreAndPlay(entity: child, depth: depth + 1)
                            }
                        }

                        exploreAndPlay(entity: rootEntity, depth: 0)

                        if !foundValidAnimation {
                            print("⚠️ 警告：未找到有效骨骼动画（可能全是 default）")
                        }
                    }
                } catch {
                    print("❌ 加载失败: \(error)")
                }

                print("--------- 🔍 扫描结束 ---------\n")
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title).foregroundStyle(.white)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(20)
        }
    }
}

#Preview {
    DebugManulView()
}
