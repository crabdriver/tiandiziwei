# 看盘啦

**看盘啦** 是基于 SwiftUI 的 iOS 紫微斗数排盘应用（主屏与系统显示名为「看盘啦」）。

排盘逻辑继承「点亮星空」体系，并与既有 Android APK 的实际行为尽量对齐，便于对照样本做校准与回归。

## 项目结构

- `ZiWeiDoushuDianLiangXingKong/`: 应用源码
  - `Models/ZiWeiEngine.swift`: 排盘核心引擎（安星、四化、大限、长生等）
  - `Models/LunarCalendar.swift`: 农历转换、干支计算、节气判定
  - `Models/FlowYearStars.swift`: 流年星系与大限宫位计算
  - `ViewModels/ChartViewModel.swift`: 输入处理与排盘调度
  - `Utils/ColorTheme.swift`: 界面配色、渐变、`ChartPalette`（星曜/四化展示色）
  - `Views/InputView.swift`: 生辰输入页
  - `Views/ZiWeiChartView.swift`: 命盘棋盘式渲染
  - `Views/PalaceDetailContent.swift`: 单宫详情（盘面点击与「排盘详情」列表复用）
  - `Views/ChartDisplayView.swift`: 排盘结果（命盘 / 详情切换）
- `ZiWeiDoushuDianLiangXingKongTests/`: 单元测试（解析层与纯函数，见下「单元测试」）
- `ZiWeiDoushuDianLiangXingKong.xcodeproj/`: Xcode 工程
- `project.yml`: **Xcode 工程唯一配置源**（XcodeGen）；详见 `docs/工程配置说明.md`
- `scripts/regenerate-xcode-project.sh`: 在 macOS 上根据 `project.yml` 重新生成 `project.pbxproj`
- `docs/项目现状与规划.md`: 项目现状、方向与近期进展
- `docs/工程配置说明.md`: XcodeGen 单一配置源与生成流程
- `.github/workflows/ios-test.yml`: GitHub Actions，在 macOS 上自动跑单元测试

界面风格（暖纸底、夜空英雄区、朱砂宫名、结果页材质分段等）集中在 `Utils/ColorTheme.swift` 与各 `Views`，**不涉及排盘数据计算**。

## 已对齐的排盘逻辑

以下内容已通过多轮 APK 样本回归验证：

### 宫位与星曜
- 十二宫安排与宫干
- 主星：紫微系（紫微、天机、太阳、武曲、天同、廉贞）、天府系（天府、太阴、贪狼、巨门、天相、天梁、七杀、破军）
- 辅星：左辅、右弼、文昌、文曲、天魁、天钺
- 煞星：火星、铃星、擎羊、陀罗、地空、地劫
- 杂曜：天官、天福、天哭、天虚、龙池、凤阁、红鸾、天喜、孤辰、寡宿、天马、天刑、天姚、解神、天巫、天月、阴煞、台辅、封诰、三台、八座、恩光、天贵、天才、天寿、截空、旬空、副旬等
- 长生十二神
- 禄存、天马

### 四柱与四化
- 年柱按立春精确时刻切换（非固定按日）
- 月柱按节气精确时刻判定月序
- 日柱独立计算，子时（23 点）进入次日干支
- 时柱按日干起时
- 四化（化禄、化权、化科、化忌）按排盘年干

### 大限与方向
- 五行局确定大限起始年龄
- 阳男阴女顺行、阴男阳女逆行
- 大限年龄段正确分配到各宫位

### 辅助字段
- 来因宫（宫干等于生年天干的宫位）
- 命主、身主
- 流年干支、流斗、虚岁
- 旬空 / 副旬（按年干阴阳区分顺序）
- 天魁 / 天钺（按 APK 实际映射表）

### 时间输入
- 真太阳时输入模式
- 北京时间（钟表时间）输入模式，自动转真太阳时
- 阴历时间输入模式，自动转公历再转真太阳时
- 换月（月调整）逻辑
- 闰月标志规范化：非实际闰月年份时自动忽略

## 暂未实现

- **`层2.1` / `层3.1`**：APK 中由 native 库 `libziweixingyu.so` 计算的分析标记，属于 AI 辅助分析而非传统排盘规则，iOS 版暂不实现。代码中保留了 `layer2Gong` / `layer3Gong` 字段供后续扩展。

## 开发环境

- Xcode
- iOS 17.0+（使用 SwiftUI `onChange` 双参数形式等 API）
- Swift 5.9

## 运行方式

1. 用 Xcode 打开 `ZiWeiDoushuDianLiangXingKong.xcodeproj`
2. 选择模拟器或真机
3. 运行 `ZiWeiDoushuDianLiangXingKong` target

## 单元测试

工程内包含 `ZiWeiDoushuDianLiangXingKongTests` target。在 Xcode 中选择该 scheme 或按 `⌘U` 运行测试。

| 测试文件 | 内容 |
|----------|------|
| `ChartInputTests.swift` | `ChartInput` / `fromApkString`、多模式参数串往返 |
| `LunarCalendarConverterTests.swift` | 时辰索引、闰月与月天数等 |
| `TrueSolarTimeTests.swift` | 均时差、标准经度下真太阳时 |
| `ZiWeiEnginePureHelpersTests.swift` | 四化表、地支运算、命宫/身宫公式等（**不调用** `generateChart` 整盘） |

## CI（自动测试）

推送到 `main` / `master` 或提交 **Pull Request** 时，[GitHub Actions](https://docs.github.com/en/actions) 会在 **macOS** Runner 上对模拟器执行 `xcodebuild test`（工作流：`.github/workflows/ios-test.yml`）。需在仓库中启用 Actions；若模拟器名称与 Runner 上 Xcode 不匹配，可编辑该文件中的 `-destination`。

## Xcode 工程配置（单一来源）

**以 `project.yml` 为准**，不要用 Xcode 长期手改 `project.pbxproj` 与 YAML 双头维护。修改流程与 `xcodegen` 命令见 **`docs/工程配置说明.md`**；仓库内仍保留生成的 `project.pbxproj` 便于未安装 XcodeGen 时直接打开工程。

## 说明

本项目仍以持续校准与对照 APK 样本为主；单元测试用于锁定输入解析等工程层行为，**排盘算法回归**仍建议结合既有样本集。

已通过的样本覆盖以下边界条件：真太阳时 vs 北京时间输入、子时跨日、节气边界（立春 / 惊蛰等精确时刻）、换月开关、闰月年份、不同性别的大限方向。如果后续补充更多规则或修改逻辑，建议以现有样本做回归校验后再提交。
