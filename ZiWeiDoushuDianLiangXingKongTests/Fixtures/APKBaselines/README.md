# APK Baseline Fixtures

本目录存放来自真实 APK 运行结果的 JSON fixture，供测试 bundle 加载。

## 契约

- 顶层字段固定为：`id`、`input`、`expected`、`source`
- `input` 至少包含 `apkRaw`，并由 `ChartInput.fromApkString(_:)` 解析
- `expected.global` 只写已经从 APK 侧确认过的字段
- `expected.global.siHuaInfo` 为可选数组，字符串格式必须与 `ZiWeiChartComparableSnapshot` 保持一致：`星曜:化X`
- `expected.global.siHuaInfo` 的顺序必须与快照排序规则一致：`化禄`、`化权`、`化科`、`化忌`；同类再按整条字符串字典序
- `expected.palaces` 在暂无已确认宫位细节时写 `[]`
- `expected.palaces[].majorStarNames` 为可选数组，只表示该宫 `majorStars` / 正曜，不包含辅曜、煞曜、杂曜
- `source` 记录样本来源、文档和附加说明，便于追溯

## 当前样本

- `core-fields-smoke.json`
  - 真太阳时参数串：`圻拆祗柝袛祇#2|2026|03|27|22|34|24|120.000000|-8|1|0`
  - 北京时间参数串：`圻拆祗柝袛祇#1|2026|3|27|22|39|43|120.0|-8|1|0`
  - 已确认输出：`命宫=辰`、`身宫=寅`、`命主=廉贞`、`身主=铃星`
- `daxian-direction-smoke.json`
  - 真太阳时参数串：`圻拆祗柝袛祇#2|2026|03|27|22|34|24|120.000000|-8|1|0`
  - 已确认输出：`isShun=true`，以及 12 宫大限年龄段
- `sihua-smoke.json`
  - 真太阳时参数串：`圻拆祗柝袛祇#2|2026|04|01|10|07|15|120.000000|-8|1|0`
  - 已确认输出：`天同:化禄`、`天机:化权`、`文昌:化科`、`廉贞:化忌`
- `star-placement-smoke.json`
  - 真太阳时参数串：`圻拆祗柝袛祇#2|2026|03|28|08|37|08|120.000000|-8|1|0`
  - 已确认输出：`辰=武曲/七杀`、`卯=天同/天梁`、`戌=廉贞/贪狼`

## 约束

- 不要用 iOS 当前输出反填 `expected`
- 未确认字段宁可省略，也不要猜测
