# 看盘啦：第三批 APK 基线样本设计（四化 + 主星落宫）

日期：2026-03-28

## 1. 背景

当前项目已经完成了前两批 APK 基线闭环：

- 第一批锁定 `命宫`、`身宫`、`命主`、`身主`
- 第二批锁定 `大限方向` 与 12 宫 `daXian` 年龄段

这两批都遵守同一个原则：`APK 实际输出是唯一真值来源，iOS 只能被比较，不能反向填写 expected`。

下一步要扩展的目标是：

- `四化`
- `主星落宫`

用户已明确要求在本轮完成后，将代码整理并上传到 GitHub。

## 2. 本轮目标

本轮目标不是一次性把整张盘所有剩余字段全部锁死，而是继续沿用“小而真”的基线策略，为以下两类结果增加真实 APK 样本回归：

- 一条真实样本，专门用于 `siHuaInfo`
- 一条真实样本，专门用于少量“可明确确认”的 `主星落宫`

本轮完成后，应满足以下结果：

- 仓库内新增两条第三批真实 APK fixture
- 回归测试能自动比较这两类字段
- 基线脚本与完整测试均可通过
- 变更整理为 commit，并推送到 GitHub 远端分支

## 3. 设计原则

### 3.1 真实 APK 证据优先

所有新增 `expected` 字段必须来自真实 APK 的可见证据：

- 真实 APK 输入串
- 真实盘面截图
- 读取位置说明
- 人工判断备注

如果某个字段在 APK 上看不清，或者解释口径不稳定，就不纳入该条 fixture。

### 3.2 双样本分层，而不是单样本贪多

本轮采用“双样本分层”而不是“单新样本全覆盖”：

- `sihua-smoke.json` 只负责四化
- `star-placement-smoke.json` 只负责主星落宫

这样可以降低单条样本的人肉抄录压力，也能避免某个字段看不清时拖住整批实现。

### 3.3 只扩测试契约，不扩业务逻辑

本轮预期只需要扩展 fixture 契约、loader / regression tests 与相关测试资源打包。

不应为了这批样本去修改：

- `ZiWeiEngine` 的排盘算法
- UI 展示逻辑
- 快照层已具备但当前不需要的复杂字段组织方式

## 4. 样本策略

### 4.1 样本 A：四化样本

目标：找到一条在 APK 盘面上能清晰读出四化总表的样本。

该样本用于：

- 固定 `input.apkRaw`
- 记录 `source.apkClockRaw`
- 记录四化读取说明
- 生成 `sihua-smoke.json`

该样本只要求写入 `expected.global.siHuaInfo`，不要求同时承担主星落宫。

### 4.2 样本 B：主星落宫样本

目标：找到一条在 APK 盘面上能清晰确认若干宫位主星的样本。

该样本用于：

- 固定 `input.apkRaw`
- 记录 `source.apkClockRaw`
- 记录主星读取说明
- 生成 `star-placement-smoke.json`

该样本不要求一次覆盖 12 宫所有主星，只要求覆盖若干“肉眼可明确确认”的宫位。

## 5. 数据契约设计

### 5.1 `expected.global` 扩展

在 `APKBaselineCase.Expected.Global` 中新增可选字段：

- `siHuaInfo: [String]?`

编码形式直接与 `ZiWeiChartComparableSnapshot.Global.siHuaInfo` 对齐，即使用已排序的字符串数组，形如：

```json
["廉贞:化禄", "破军:化权", "武曲:化科", "太阳:化忌"]
```

这里的“已排序”不是按星名简单排序，而是必须与当前快照实现完全一致：

- 先按 `化禄 -> 化权 -> 化科 -> 化忌` 的顺序
- 同类目内再按当前 `compareSiHuaEntry` 规则比较整串

换句话说，fixture 中的 `siHuaInfo` 应与本地生成的 `snapshot.global.siHuaInfo` 逐元素一致，而不是由人工另行发明排序规则。这样可以避免在 fixture 层重复定义字典排序语义。

### 5.2 `expected.palaces` 扩展

在 `APKBaselineCase.PalaceExpectation` 中新增可选字段：

- `majorStarNames: [String]?`

保留现有：

- `position: String`
- `daXian: String?`

于是宫位断言结构变为“按需填写”：

```json
{
  "position": "辰",
  "majorStarNames": ["紫微", "天相"]
}
```

这里的 `majorStarNames` 明确对应 iOS 快照层的 `majorStars`，也就是正曜 / 主星，不包含辅星、杂曜与煞星。

本轮不扩展以下字段：

- 辅星
- 杂曜
- 星曜亮度
- 星上四化
- 宫干四化 / 自化 / 冲化

这些字段虽然快照层已支持部分表达，但不属于本轮最小闭环。

## 6. 回归断言设计

### 6.1 四化断言

在 `APKBaselineRegressionTests` 中新增：

- `snapshot.global.siHuaInfo` 对 `fixture.expected.global.siHuaInfo`

仅在 fixture 提供该字段时比较。

### 6.2 主星落宫断言

在 `APKBaselineRegressionTests` 中对 `fixture.expected.palaces` 逐项比较：

- 先通过 `position` 找到对应宫位
- 读取 `snapshot.palace(at:)?.majorStars.map(\.name)`
- 将其归一为稳定顺序
- 与 `majorStarNames` 比较

仅在 fixture 提供 `majorStarNames` 时比较。

### 6.3 Loader 测试

新增或更新 loader 测试，确认：

- 新 fixture 可被 bundle 正常加载
- `siHuaInfo` 能正确解码
- `majorStarNames` 能正确解码

## 7. 采样与落地流程

### 7.1 先采样，后写 fixture

每条样本都必须先完成以下步骤，再进入 JSON：

1. 取得新的真实 APK 输入串
2. 保存对应盘面截图
3. 记录字段读取位置与口径
4. 只把已确认字段写入 fixture

禁止边看 iOS 输出边回填 `expected`。

### 7.2 TDD 执行顺序

本轮实现遵守测试先行：

1. 先写失败测试
2. 运行并确认失败原因正确
3. 最小扩展 `APKBaselineCase` / regression assertions
4. 加入新 fixture
5. 跑基线脚本
6. 跑完整测试

## 8. 风险与约束

### 8.1 当前最大风险

当前最大的风险不是代码实现，而是 APK 证据读取：

- 输入页 `shuruye` 未导出，批量采样仍不够顺畅
- `uiautomator` 不能直接读取自定义 View 内文字
- 因此第三批仍依赖截图人工确认

### 8.2 约束控制

为降低错误率，本轮明确限制：

- 不追求单样本全覆盖
- 不追求 12 宫主星一次性全锁
- 不把看不清的字段写入 fixture
- 不为方便测试而改动生产排盘逻辑

## 9. 验证计划

完成实现后，至少执行以下验证：

1. `xcodebuild test` 定向运行：
   - `APKBaselineLoaderTests`
   - `APKBaselineRegressionTests`
2. `./scripts/run-apk-baseline-tests.sh`
3. 完整 `xcodebuild test`
4. 对新增或修改文件运行 `ReadLints`
5. 确认新 fixture 已进入测试 target 的资源打包范围，并能被 loader 在测试 bundle 中读取

## 10. 完成标准

满足以下条件时，本轮视为完成：

- 已新增 `sihua-smoke.json`
- 已新增 `star-placement-smoke.json`
- `APKBaselineCase` 已支持四化和主星落宫最小契约
- 回归测试已能比较 `siHuaInfo` 与所选宫位主星
- 基线脚本与完整测试全部通过
- 变更已提交并推送到 GitHub

## 11. 非目标

本轮明确不做：

- 一次性覆盖所有宫位全部主星
- 覆盖辅星 / 杂曜 / 星曜亮度
- 覆盖宫干四化 / 自化 / 冲化
- 修改排盘引擎逻辑来“适配”样本
- 大规模重写 `capture-workflow` 或 APK 自动化链路
