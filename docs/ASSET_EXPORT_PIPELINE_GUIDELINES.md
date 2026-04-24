# Asset Export Pipeline Guidelines
# 狲爷气象台 3D 资产导出规范

本文档定义当前项目的角色资产导出规范，目标不是追求“理论上最完整”的 USDZ 管线，而是保证 `Blender -> USDZ -> RealityKit` 在当前项目里稳定可复用、可验证、可迭代。

---

## 1. 结论先行

当前项目的默认生产方案是：

- `Manul.usdz` 只承担主模型、骨骼、材质和稳定待机能力
- 每个动作单独导出为一个 `Manul_<action>.usdz`
- App 运行时从单动作 USDZ 中提取动画资源，不把这些动作包直接加入场景

当前仓库已经按这套方式组织：

- 主模型：[Manul.usdz](/Users/bluedavy/Desktop/ManulForecast/WeatherAssets/Sources/WeatherAssets/Manul.usdz)
- 动作包：
  - [Manul_lookleft.usdz](/Users/bluedavy/Desktop/ManulForecast/WeatherAssets/Sources/WeatherAssets/Manul_lookleft.usdz)
  - [Manul_lookright.usdz](/Users/bluedavy/Desktop/ManulForecast/WeatherAssets/Sources/WeatherAssets/Manul_lookright.usdz)
  - [Manul_nodsleepy.usdz](/Users/bluedavy/Desktop/ManulForecast/WeatherAssets/Sources/WeatherAssets/Manul_nodsleepy.usdz)
  - [Manul_shiver.usdz](/Users/bluedavy/Desktop/ManulForecast/WeatherAssets/Sources/WeatherAssets/Manul_shiver.usdz)
  - [Manul_shakewater.usdz](/Users/bluedavy/Desktop/ManulForecast/WeatherAssets/Sources/WeatherAssets/Manul_shakewater.usdz)
  - [Manul_tilt.usdz](/Users/bluedavy/Desktop/ManulForecast/WeatherAssets/Sources/WeatherAssets/Manul_tilt.usdz)

---

## 2. 为什么当前不默认做“一个 USDZ 装多个动作”

### 2.1 USD / RealityKit 本身不是根本限制

Apple 的 RealityKit 资产模型可以暴露动画库，`Entity.availableAnimations` 也说明实体可以持有多个动画资源。

基于 Apple 在 WWDC25 的说明，可以推断：

- `USD/USDZ` 资产本身可以承载多个动画
- RealityKit 也有能力读取多动画资产
- Apple 甚至提供过把动画追加到 USDZ 的工具链思路

这里的关键判断是**推断**：当前项目卡住的主要不是 USDZ 格式本身，而是 Blender 这条导出链在“多独立动作片段”上的稳定性。

### 2.2 当前主要限制来自 Blender 的 USD 导出行为

Blender 官方手册对 USD 导出的描述更偏“导出场景与时间轴动画”：

- 导出动画时，默认基于场景帧范围导出
- 导出器并不强调把多个 Action / NLA 片段稳定打成可命名动画库
- 导出能力整体偏基础，不适合作为复杂角色动作片段管理工具

对当前项目的实际影响是：

- 多个动作容易被烘进同一条时间采样轨道
- 导出后在 RealityKit 中常常只能稳定取到一条默认动画，或动作命名不稳定
- 一旦骨骼、时间段、命名有偏差，排查成本很高

因此当前项目不把“一个 USDZ 装全部动作”作为默认生产方案。

---

## 3. 当前项目的资产组织规则

### 3.1 主模型文件

主模型文件固定为：

- `Manul.usdz`

职责：

- 主网格
- 主材质
- 主骨骼
- 稳定的层级结构
- 可以包含 idle，但不能依赖它承担全部动作库存

要求：

- 这是 App 真正入场景的角色实体
- 后续新增动作时，尽量不改它的骨骼层级和绑定关系

### 3.2 动作文件

动作文件固定命名为：

- `Manul_<action>.usdz`

例如：

- `Manul_lookleft.usdz`
- `Manul_shakewater.usdz`
- `Manul_nodsleepy.usdz`

职责：

- 只作为“动画灵魂包”
- 运行时只提取动画，不直接挂到场景

要求：

- 每个动作包只包含一个动作片段
- 使用与主模型一致的骨骼层级、rest pose、命名和绑定
- 不额外引入新骨骼、新 mesh 变体、新材质分支

---

## 4. Blender 制作规则

### 4.1 骨骼与模型规则

- 所有动作必须使用同一套 Armature
- 不允许在某个动作文件里新增、删除或重命名骨骼
- 主模型和动作包必须使用同一套 rest pose
- 不允许为单个动作单独改 mesh 拓扑
- 不允许导出“同动作不同缩放版本”的角色文件

原因：

- 当前项目运行时是把动作资源重定向到主模型骨骼上播放
- 只要骨骼层级或 rest pose 不一致，就容易出现动画错绑、偏移、抖动或根本不能播

### 4.2 动画制作规则

- 角色动作优先通过骨骼动画完成，不要依赖对象级整体位移来做主表现
- 一个 Blender 场景文件只处理一个清晰目的：
  - 主模型文件
  - 或某一个动作文件
- 动作导出前，确保导出帧范围只覆盖该动作本身
- 不要把多个动作连在一个长时间轴里再指望导出器自动拆 clip

原因：

- Blender 的 USD 导出更接近“导整个时间范围”
- 当前项目目标是稳定提取独立动作，而不是在导出阶段做复杂 clip 管理

### 4.3 场景内容规则

- 不要把相机一起作为正式角色资产导出
- 不要把灯光一起作为正式角色资产导出
- 不要在动作包里塞调试辅助物体
- 不要把天气特效并进角色动作包

原因：

- 项目里的镜头、光照、天气特效在 App 侧统一控制
- 角色资产里混入相机和灯光会增加清理成本，也容易污染 RealityKit 层级

---

## 5. 导出规则

### 5.1 主模型导出

主模型导出产物：

- `Manul.usdz`

导出要求：

- 保留主网格、主骨骼、主材质
- 层级结构稳定
- 若 idle 在导出后能稳定读取，可保留；若不稳定，不强依赖

验收标准：

- App 内可稳定加载
- `Armature` 节点可被定位
- 角色尺寸、朝向和材质正常

### 5.2 动作包导出

每个动作单独导出为：

- `Manul_<action>.usdz`

导出要求：

- 只导出一个动作片段
- 与主模型使用同一套骨骼结构
- 动作包导出后，App 侧能稳定提取一条真实动画

验收标准：

- `extractFirstRealAnimation()` 能取到该动作
- 在主模型 `Armature` 上播放时无明显骨骼错位
- 动作命名可以不完全依赖导出名，但文件名必须可读

---

## 6. 命名规范

### 6.1 文件命名

- 主模型：`Manul.usdz`
- 单动作包：`Manul_<verb>.usdz`

动作名要求：

- 使用英文小写
- 使用动词或清晰动作短语
- 不使用空格
- 不使用版本号直接写入文件名

推荐示例：

- `Manul_lookleft.usdz`
- `Manul_lookright.usdz`
- `Manul_shakewater.usdz`
- `Manul_nodsleepy.usdz`

不推荐示例：

- `Manul final motion.usdz`
- `Manul动作1.usdz`
- `Manul_new_v7.usdz`

### 6.2 版本管理

如果动作需要迭代，不在正式资源目录中堆多版本命名。

建议做法：

- Blender 源文件中保留版本
- 导入项目时只保留当前生效的正式产物

---

## 7. 导入项目规范

统一导入到：

- [WeatherAssets Swift Package 资源目录](/Users/bluedavy/Desktop/ManulForecast/WeatherAssets/Sources/WeatherAssets)

规则：

- 主模型和动作包都进入 `WeatherAssets` 包管理，并在 `Package.swift` 的 `resources` 中显式复制
- 天气特效类资源按独立资源处理，例如：
  - [Rain.usdz](/Users/bluedavy/Desktop/ManulForecast/ManulForecast/models/Rain.usdz)
- 不把动作包直接散落在 App 主 target 中

原因：

- 当前项目已经以 `WeatherAssets` 为统一角色资产入口
- 这样命令行构建、Widget target、主 App target 的资源引用更稳定

---

## 8. 导入后验证清单

每次替换主模型或新增动作包后，至少做以下验证：

1. App 能正常加载 `Manul.usdz`
2. `Armature` 节点仍然存在且可找到
3. 新动作文件能被加载
4. `extractFirstRealAnimation()` 能提取到真实动画
5. 动作能在主模型上播放
6. 没有明显的骨骼错位、比例漂移、朝向错误或材质异常

如果任一项失败，先回查：

- 骨骼命名是否变化
- rest pose 是否变化
- 动作包是否包含多段时间轴
- Blender 导出范围是否导错

---

## 9. 当前项目的推荐生产流程

### Step 1

在 Blender 维护主角色工程，锁定：

- mesh
- armature
- rest pose
- 材质基线

### Step 2

为每个动作建立独立导出流程：

- 打开同一骨骼体系
- 只保留一个动作片段的导出帧范围
- 导出为 `Manul_<action>.usdz`

### Step 3

把主模型与动作包放入：

- `WeatherAssets/Sources/WeatherAssets`

### Step 4

在 App 中验证：

- 主模型加载
- 动作提取
- 动作回放

### Step 5

通过后再接入行为系统和天气状态映射

---

## 10. 后续升级路线

如果未来动作数量继续增长，可以再评估更重的资产管线，例如：

- 保留 Blender 作为动画制作工具
- 但不再依赖 Blender 直接输出“多动作最终 USDZ”
- 改为单动作导出后，在后处理阶段使用 USD 工具链或 Apple 工具链做拼装

当前阶段不建议直接切这条路线。

原因：

- 工程成本高
- 调试难度高
- 对当前首发目标没有决定性收益

---

## 11. 一句话规范

当前项目的默认规则是：

> 主模型一个文件，动作一个文件一个包，同骨骼、同姿态、同命名，不赌 Blender 一次导出多动作的稳定性。

---

## 12. 参考资料

以下是本规范主要参考的官方资料：

- Blender 官方手册，USD 导出：
  - [https://docs.blender.org/manual/en/latest/files/import_export/usd.html](https://docs.blender.org/manual/en/latest/files/import_export/usd.html)
- Apple 官方文档，RealityKit `Entity.availableAnimations`：
  - [https://developer.apple.com/documentation/realitykit/entity/availableanimations](https://developer.apple.com/documentation/realitykit/entity/availableanimations)
- Apple 官方视频，WWDC25《Bring your SceneKit project to RealityKit》：
  - [https://developer.apple.com/videos/play/wwdc2025/288/](https://developer.apple.com/videos/play/wwdc2025/288/)

其中关于“USDZ 能承载多动画，但当前项目默认不采用 Blender 单文件多动作导出”的判断，属于基于官方资料和本项目现状做出的工程性推断。
