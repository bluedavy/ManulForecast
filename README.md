# Manul Forecast

## 中文版

Manul Forecast 是一款由天气驱动的兔狲陪伴式天气 App。它不是把宠物挂件叠在传统天气页面上，而是让天气状态直接影响兔狲的动作、情绪、光照、雨雪氛围和 Widget 表达。

当前版本是 v1 原型，用来验证一个核心想法：天气 App 除了有用，能不能也让用户每天打开时像是在看看“今天这只住在天气里的兔狲过得怎么样”。

### 主要功能

- 使用 SwiftUI、RealityKit 和 Reality Composer Pro 资产构建 3D 兔狲主舞台。
- 支持晴天、雨天、雪天和不同时间段状态切换。
- 将天气状态映射到兔狲行为，包括待机动作、点击反馈、雨天反应、雪天反应和随机环境动作。
- 通过背景渐变、灯光变化、天体符号和雨水粒子营造天气氛围。
- 包含 Widget 扩展，并沉淀了 App 与 Widget 共享的天气展示概念。
- 保留 Blender 源工程 `ManulModels/Manul.blend`，方便继续迭代 3D 资产。

### 产品方向

Manul Forecast 的目标不是做一个普通天气 App 加一个宠物形象，而是让天气本身变得更有角色感：

- 足够有用，可以快速完成日常天气判断。
- 足够有趣，让晴、雨、雪、夜间状态有明确差异。
- 足够克制，避免传统天气 App 的广告干扰和信息噪音。

v1 阶段会聚焦在首页主舞台、兔狲状态系统、Widget 表达和少量高质量天气状态上。

### 技术栈

- SwiftUI
- RealityKit
- WidgetKit
- Reality Composer Pro asset package
- USDZ 动画资产
- Blender 源模型文件

### 仓库结构

```text
ManulForecast/
  ManulForecast/              iOS App 源码
  ManulForecastWidget/        Widget 扩展
  WeatherAssets/              包含 RealityKit 资产的本地 Swift Package
  ManulModels/                Blender 源工程文件
  Config/                     Widget Info.plist 和共享配置
  docs/                       产品、路线图和技术文档
```

### 3D 资产管线

App 从 `WeatherAssets` 加载主兔狲模型，并从独立 USDZ 文件中提取动作：

- `Manul.usdz`：主模型和 idle 动画
- `Manul_lookright.usdz`
- `Manul_lookleft.usdz`
- `Manul_tilt.usdz`
- `Manul_shakewater.usdz`
- `Manul_shiver.usdz`
- `Manul_nodsleepy.usdz`

原始 Blender 工程位于：

```text
ManulModels/Manul.blend
```

### 本地运行

环境要求：

- macOS + Xcode 26.x
- 已安装 iOS Simulator runtime
- 已安装 Xcode iOS 平台支持组件

打开工程：

```bash
open ManulForecast.xcodeproj
```

然后选择 `ManulForecast` scheme，在 iOS Simulator 上运行。

### 当前状态

项目正在 v1 开发阶段。当前代码已经跑通了核心技术路径：

- 3D 模型加载
- 从 USDZ 资产提取动画
- 天气驱动的行为动作池
- 雨水粒子控制
- 昼夜光照变化
- Widget 展示结构雏形

接下来的重点是从原型接线走向更完整的 v1 产品结构，包括共享状态模型、首页舞台拆分、晴/雨/雪行为打磨和生产级 Widget 状态。

### 大文件说明

项目包含 3D 资产。当前仓库历史已经清理过，大文件不超过 GitHub 的 100 MB 限制；目前最大的文件是 `WeatherAssets/Sources/WeatherAssets/WeatherAssets.rkassets/Manul.usdz`，约 11 MB。如果后续 3D 资产继续变大，可以考虑使用 Git LFS。

### 文档

更详细的产品和实现文档在 `docs/` 目录：

- `docs/PRD_V1_PRODUCT_FRAMEWORK.md`
- `docs/CURRENT_TECHNICAL_IMPLEMENTATION.md`
- `docs/V1_ROADMAP_AND_TECH_PRIORITIES.md`
- `docs/ASSET_EXPORT_PIPELINE_GUIDELINES.md`
- `docs/ASSET_DELIVERY_CHECKLIST_TEMPLATE.md`

---

## English

Manul Forecast is a weather-driven companion weather app built around a 3D Pallas's cat. Instead of treating weather as a plain data board, the app lets the weather drive the cat's mood, motion, lighting, rain effects, and widget presentation.

The current version is a v1 prototype for validating the core product idea: can a useful weather app also feel like checking in on a quiet, slightly grumpy little roommate who lives inside the weather?

## What It Does

- Shows a 3D Pallas's cat stage powered by SwiftUI, RealityKit, and Reality Composer Pro assets.
- Switches between sunny, rainy, snowy, and time-of-day states.
- Maps weather state to character behavior, including idle motion, tap reactions, rain reactions, snow reactions, and random ambient actions.
- Renders weather atmosphere through gradients, lighting changes, celestial symbols, and rain particles.
- Includes a Widget extension with shared weather presentation concepts.
- Keeps the original Blender source project in `ManulModels/Manul.blend` for asset iteration.

## Product Direction

Manul Forecast is not a traditional weather app with a pet pasted on top. The goal is to make the weather itself feel characterful:

- Useful enough for quick daily weather checks.
- Expressive enough that sunny, rainy, snowy, and night states feel different.
- Calm and polished enough to avoid the noise of typical ad-heavy weather apps.

The v1 focus is intentionally narrow: home stage, character state, widget expression, and a small set of high-quality weather states.

## Tech Stack

- SwiftUI
- RealityKit
- WidgetKit
- Reality Composer Pro asset package
- USDZ animation assets
- Blender source model files

## Repository Structure

```text
ManulForecast/
  ManulForecast/              iOS app source
  ManulForecastWidget/        Widget extension
  WeatherAssets/              Local Swift package with RealityKit assets
  ManulModels/                Blender source project files
  Config/                     Widget Info.plist and shared config
  docs/                       Product, roadmap, and technical notes
```

## 3D Asset Pipeline

The app loads the main cat model from `WeatherAssets` and extracts motion from separate USDZ animation files:

- `Manul.usdz`: main model and idle animation
- `Manul_lookright.usdz`
- `Manul_lookleft.usdz`
- `Manul_tilt.usdz`
- `Manul_shakewater.usdz`
- `Manul_shiver.usdz`
- `Manul_nodsleepy.usdz`

The original Blender project is included at:

```text
ManulModels/Manul.blend
```

## Running Locally

Requirements:

- macOS with Xcode 26.4.x
- iOS platform support installed in Xcode
- iOS Simulator runtime available

Open the project in Xcode:

```bash
open ManulForecast.xcodeproj
```

Then select the `ManulForecast` scheme and run it on an iOS Simulator.

If Xcode reports that an iOS platform is missing, install it from:

```text
Xcode > Settings > Components
```

## Current Status

This repository is in active v1 development. The current code already demonstrates the key technical path:

- 3D model loading
- animation extraction from USDZ assets
- weather-driven behavior pools
- rain particle control
- time-of-day lighting changes
- widget presentation groundwork

The next major work is to move from prototype wiring toward a more polished v1 product structure: shared state models, cleaner home-stage composition, deeper rainy/snowy/sunny behavior, and production-ready widget states.

## Notes On Large Files

This project includes 3D assets. The repository history has been cleaned, and no file currently exceeds GitHub's 100 MB hard limit. The largest current file is `WeatherAssets/Sources/WeatherAssets/WeatherAssets.rkassets/Manul.usdz`, at about 11 MB. If future source assets grow significantly, Git LFS should be considered.

## Documentation

More detailed product and implementation notes live in `docs/`:

- `docs/PRD_V1_PRODUCT_FRAMEWORK.md`
- `docs/CURRENT_TECHNICAL_IMPLEMENTATION.md`
- `docs/V1_ROADMAP_AND_TECH_PRIORITIES.md`
- `docs/ASSET_EXPORT_PIPELINE_GUIDELINES.md`
- `docs/ASSET_DELIVERY_CHECKLIST_TEMPLATE.md`
