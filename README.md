# Manul Forecast

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

This project includes 3D assets. The current `Manul.usdz` asset is about 11 MB, but the Git history contains an earlier 73.81 MB version of the same file. GitHub may show a large-file warning because it scans pushed history, not only the latest working tree. If future source assets grow toward GitHub's 100 MB hard limit, Git LFS should be considered.

## Documentation

More detailed product and implementation notes live in `docs/`:

- `docs/PRD_V1_PRODUCT_FRAMEWORK.md`
- `docs/CURRENT_TECHNICAL_IMPLEMENTATION.md`
- `docs/V1_ROADMAP_AND_TECH_PRIORITIES.md`
- `docs/ASSET_EXPORT_PIPELINE_GUIDELINES.md`
- `docs/ASSET_DELIVERY_CHECKLIST_TEMPLATE.md`
