# APK Baseline Fixtures

本目录存放来自真实 APK 运行结果的 JSON fixture，供测试 bundle 加载。

## 契约

- 顶层字段固定为：`id`、`input`、`expected`、`source`
- `input` 至少包含 `apkRaw`，并由 `ChartInput.fromApkString(_:)` 解析
- `expected.global` 只写已经从 APK 侧确认过的字段
- `expected.palaces` 在暂无已确认宫位细节时写 `[]`
- `source` 记录样本来源、文档和附加说明，便于追溯

## 当前样本

- `core-fields-smoke.json`
  - 真太阳时参数串：`圻拆祗柝袛祇#2|2026|03|27|22|34|24|120.000000|-8|1|0`
  - 北京时间参数串：`圻拆祗柝袛祇#1|2026|3|27|22|39|43|120.0|-8|1|0`
  - 已确认输出：`命宫=辰`、`身宫=寅`、`命主=廉贞`、`身主=铃星`

## 约束

- 不要用 iOS 当前输出反填 `expected`
- 未确认字段宁可省略，也不要猜测
