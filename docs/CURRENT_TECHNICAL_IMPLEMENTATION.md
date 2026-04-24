# Current Technical Implementation Document  
# Manul Forecast (v1.0 Preparation)

本文档基于对现有 Swift 代码的静态分析，供新 AI 开发者快速理解 RealityKit/3D 集成逻辑，无需逐行阅读源码。

---

## 1. 功能特性概览 (Feature Set)

### 1.1 用户交互 (User Interactions)

| 交互类型 | 实现位置 | 行为描述 |
|---------|----------|----------|
| **Tap 手势** | `ContentView.body` → `.onTapGesture` | 点击全屏触发 `lookright` 动画，在 `Armature` 节点上播放，过渡时长 0.5s |
| **天气切换按钮** | Overlay `Button` (sun icon) | 调用 `currentWeather.next()` 循环切换 `WeatherType`；雨天/雪天触发 `triggerImmediateReaction`，晴天则重启 `startBehaviorEngine` |
| **时间段切换按钮** | Overlay `Button` (time icon) | 调用 `currentTimeOfDay.next()` 循环切换 `TimeOfDay`，带动画 1.5s |
| **模型调试 Slider** | `debugOverlay` (showDebug=true) | 控制：Scale, RotY°, RotX°, posX, posY, posZ, Cam Y, TargetY |
| **气象调试 Slider** | `showWeatherDebug` 面板 | 控制：Rain Y, Intensity, Max BR, Max Spd, Stretch, Size |
| **动画探针入口** | `showAnimationProbe` 按钮 | 打开 `DebugManulView` 全屏 Cover，用于扫描并播放 Manul 内嵌动画 |

### 1.2 动画状态 (Animation States)

动画以字符串 key 存储在 `animations: [String: AnimationResource]` 中：

| Key | 来源 USDZ | 触发场景 |
|-----|-----------|----------|
| `idle` | `Manul.usdz` 的 `availableAnimations.first` | 启动时在 Armature 上无限循环播放 |
| `lookright` | `Manul_lookright.usdz` | Tap 手势 / 晴天动作池 |
| `lookleft` | `Manul_lookleft.usdz` | 晴天动作池 |
| `nodsleepy` | `Manul_nodsleepy.usdz` | 晴天 / 雪天动作池 |
| `tilt` | `Manul_tilt.usdz` | 晴天 / 雨天动作池 |
| `shakewater` | `Manul_shakewater.usdz` | 雨天动作池 / 雨天立即反应 |
| `shiver` | `Manul_shiver.usdz` | 雪天动作池 / 雪天立即反应 |

**动作池映射**（`WeatherCondition.actionPool`）：
- **sunny**: `["lookright", "lookleft", "nodsleepy", "tilt"]`
- **rainy**: `["shakewater", "tilt"]`
- **snowy**: `["shiver", "nodsleepy"]`

### 1.3 天气集成状态 (Weather Integration Status)

- **实现方式**：UI 按钮驱动，**非自动**。
- **天气类型**：`WeatherType` 枚举（晴天、小雨、中雨、大雨、暴雨、雪天）→ 映射为 `WeatherCondition`（sunny/rainy/snowy）供行为引擎使用。
- **视觉效果**：
  - 背景渐变：`WeatherType.backgroundGradient` + `TimeOfDay.skyGradient`
  - 晴天显示天体符号（太阳/月亮），雨天/雪天用 `Color.black.opacity` 乌云遮罩
  - 降雨粒子：`Rain.usdz` 从主 Bundle 加载，通过 `WeatherControl` 和 `WeatherSystem` 控制 birthRate、speed、stretchFactor、size
- **逻辑**：切换天气时同步 `rainIntensity = currentWeather.intensity`，并调用 `syncWeatherComponent()` 更新 `WeatherControl`；雨天/雪天首次切换会触发 `triggerImmediateReaction` 播放对应动画。

---

## 2. 核心技术架构 (Core Architecture)

### 2.1 3D 资产加载策略 (Asset Loading Strategy)

#### 加载方式

- **主模型**：`Entity(named: "Manul", in: weatherAssetsBundle)` — 从 `WeatherAssets` 包的 `Bundle.module` 加载 `Manul.usdz`。
- **动画包**：6 个独立 USDZ（`Manul_lookright`, `Manul_lookleft`, `Manul_shiver`, `Manul_tilt`, `Manul_shakewater`, `Manul_nodsleepy`）同样通过 `Entity(named: assetName, in: weatherAssetsBundle)` 加载。
- **雨水**：`Entity(named: "Rain", in: Bundle.main)` — 从主 App Bundle 加载 `Rain.usdz`。

#### 动画提取逻辑（Body + Soul 分离）

1. **Body（主模型）**：`Manul.usdz` 加载后作为 `baseEntity` 加入 `ManulContainer`，并加入 `content`，参与渲染。
2. **Soul（动画）**：动画包 USDZ 仅用于提取 `AnimationResource`，**不**加入 `content`：
   - 使用 `withTaskGroup` 并发加载 6 个 `Entity(named: assetName, ...)`
   - 对每个 entity 调用 `extractFirstRealAnimation(from: entity)`
   - 返回的 `AnimationResource` 存入 `animations[key]`，实体本身被丢弃
3. **idle**：从主模型 `Manul.usdz` 的 `findAnimatableEntity(in: baseEntity).availableAnimations.first` 直接获取。

#### 关键代码路径

```swift
// 动画包加载：不 content.add，只提取动画
let entity = try await Entity(named: assetName, in: weatherAssetsBundle)
let anim = await MainActor.run { extractFirstRealAnimation(from: entity) }
return (key, anim)
```

### 2.2 动画播放系统 (Animation Engine)

#### 数据结构

- **存储**：`@State private var animations: [String: AnimationResource] = [:]`
- **Keys**：`idle`, `lookright`, `lookleft`, `shiver`, `tilt`, `shakewater`, `nodsleepy`

#### 播放 Bind Point 查找逻辑

1. **优先**：`baseEntity.findEntity(named: "Armature")`
2. **fallback**：`findAnimatableEntity(in: baseEntity)` — 递归找第一个 `availableAnimations.isEmpty == false` 的子实体
3. **最后**：`baseEntity` 自身

```swift
let armature = baseEntity.findEntity(named: "Armature") ?? findAnimatableEntity(in: baseEntity) ?? baseEntity
armature.playAnimation(anim, transitionDuration: 0.5)
```

#### 系统动画过滤

- `extractFirstRealAnimation`：遍历 `entity.availableAnimations`，排除名称包含 `"default"` 或 `"global"` 的动画。
- `DebugManulView.exploreAndPlay`：同样用 `localizedCaseInsensitiveContains("default")` / `("global")` 判定 `isSystemAnim`。

#### 行为引擎（Task 驱动）

- **入口**：`startBehaviorEngine(entity:)`，在 6 个动画包加载完成后调用。
- **循环逻辑**：
  1. 随机休眠 `4~8` 秒（`Task.sleep(nanoseconds:)`）
  2. 根据 `currentWeather.weatherCondition` 获取 `actionPool`
  3. 从池中 `randomElement()` 选一个 key
  4. 若有对应 `animations[key]`，在 armature 上 `playAnimation(anim, transitionDuration: 0.5)`
- **取消**：`behaviorTask?.cancel()` 在每次重新调用 `startBehaviorEngine` 时执行。
- **切换天气**：雨天/雪天会先执行 `triggerImmediateReaction`，再调用 `startBehaviorEngine`；晴天直接启动行为引擎。

### 2.3 场景构图与渲染 (Scene Composition)

#### 硬编码默认参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `manulScale` | 1.84 | 模型整体缩放 |
| `manulRotY` | 4.0 | 绕 Y 轴旋转（度） |
| `manulRotX` | 0.0 | 绕 X 轴旋转（度） |
| `posX` | 0.07 | 容器 X 位移 |
| `posY` | -0.34 | 容器 Y 位移 |
| `posZ` | 0.0 | 容器 Z 位移 |
| `camPosY` | -0.29 | 相机 Y |
| `camTargetY` | -0.12 | Look-at 目标 Y |
| 模型本地 `scale` | (1,1,1) | 1:1 原始尺寸 |
| 模型本地 `position` | (0, -0.2, -0.5) | 加载后立即设定 |

#### 灯光与相机

- **相机**：`PerspectiveCamera`，初始 `position = (0, 1.0, 2.5)`，`look(at: [0,0,0], from: ...)`；`update` 中通过 `camPosY`、`camTargetY` 动态调整。
- **主光源 `SunLight`**：`DirectionalLightComponent`，初始 `position = (-2, 2, 2)`，`intensity = 2000`；随 `TimeOfDay` 改变 `color`、`lightPosition`、`intensityMultiplier`；雨天用 `weatherAttenuation = max(0, 1 - intensity*2)` 减弱。
- **补光 `MainCamera`**：相机实体同时挂载 `DirectionalLightComponent`，`intensity = 1000`；雨天变为冷灰/灰蓝，暴雨保留约 30% 照明。
- **IBL**：代码中未使用 `ImageBasedLightComponent`，仅使用 `DirectionalLight`。

---

## 3. 关键实现细节与防御代码 (Implementation Details)

### 3.1 递归搜索 (Recursive Search)

| 函数 | 作用 | 逻辑 |
|------|------|------|
| `findAnimatableEntity(in:)` | 找可播放骨骼动画的实体 | 若 `!entity.availableAnimations.isEmpty` 则返回自身；否则对每个 `child` 递归，先找到先返回 |
| `extractFirstRealAnimation(from:)` | 提取第一个非系统动画 | 遍历 `availableAnimations`，排除含 "default"/"global"；若无则递归子实体 |
| `WeatherSystem.findParticleEmitter(in:)` | 找粒子发射器 | 若自身有 `ParticleEmitterComponent` 则返回；否则递归子实体 |
| `sanitizeModel(_:)` | 净化模型（移除相机/灯光） | 若实体含 Camera/SpotLight/DirectionalLight/PointLight 则 `removeFromParent`；否则递归子实体 |

### 3.2 错误处理 (Error Handling)

- **Manul 加载失败**：`catch` 中 `print("❌ [MainView] Manul 加载失败: \(error)")`，不崩溃。
- **动画包加载失败**：`catch` 中 `print("❌ [动画提取] 加载 \(assetName) 失败: \(error)"`，返回 `(key, nil)`，不写入 `animations`。
- **Rain 加载失败**：空 `catch` 块，静默失败。
- **Tap 时动画未就绪**：`guard let ... animations["lookright"]` 失败时 `print("⚠️ lookright 动作未就绪")` 并 return。
- **未找到 Armature**：`print("❌ [错误] 主模型中未找到 Armature 节点")`。

### 3.3 状态驱动 3D 更新 (State Management)

- **RealityView `update` 闭包**：依赖 `@State` 变化触发重绘。关键绑定：
  - `manulScale`, `manulRotY`, `manulRotX`, `posX`, `posY`, `posZ` → `ManulContainer.transform`
  - `camPosY`, `camTargetY` → `MainCamera` 位置与 look-at
  - `currentWeather`, `currentTimeOfDay` → `RainEffect.isEnabled`、`SunLight`、`MainCamera` 灯光
  - `rainPosY` → `RainEffect.position.y`
- **`syncWeatherComponent`**：在 `onChange(of: rainIntensity/maxBirthRate/...)` 时更新 `rainEntity` 的 `WeatherControl`，并设置 `isDirty = true` 触发 `WeatherSystem` 在下帧更新粒子参数。

---

## 4. 资产清单 (Asset Inventory)

| 资产 | Bundle | 用途 |
|------|--------|------|
| `Manul.usdz` | WeatherAssets | 主骨骼模型 + idle 动画 |
| `Manul_lookright.usdz` | WeatherAssets | 动画提取 |
| `Manul_lookleft.usdz` | WeatherAssets | 动画提取 |
| `Manul_shiver.usdz` | WeatherAssets | 动画提取 |
| `Manul_tilt.usdz` | WeatherAssets | 动画提取 |
| `Manul_shakewater.usdz` | WeatherAssets | 动画提取 |
| `Manul_nodsleepy.usdz` | WeatherAssets | 动画提取 |
| `Rain.usdz` | Bundle.main | 粒子降雨特效 |

---

*文档生成依据：ContentView.swift, DebugManulView.swift, ManulForecastApp.swift, WeatherAssets.swift 及项目文件结构。*
