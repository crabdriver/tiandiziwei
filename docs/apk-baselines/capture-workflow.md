# APK 基线采集工作流

本文档描述如何把一次真实 APK 排盘结果整理成一条可回归的 JSON fixture。当前基线工作以 **真实 APK 输出** 为唯一真值来源，iOS 结果只能用于对比，不能反向回填 `expected`。

## 1. 运行前准备

- 先按 `docs/apk-baselines/runtime-setup.md` 确认 `adb`、AVD、`app.apk` 都可用。
- 先按 `docs/apk-baselines/apk-source-log.md` 核对 APK 路径与 SHA256，避免采到错误二进制。
- 当前本机已验证的最小运行链路：

```bash
ANDROID_SDK_ROOT=/opt/homebrew/share/android-commandlinetools \
  /opt/homebrew/share/android-commandlinetools/emulator/emulator \
  -avd tiandiziwei-api35 \
  -no-snapshot-save

adb -s emulator-5554 install -r /Users/wizard/work_2025/tiandiziwei/app.apk
adb -s emulator-5554 shell am start \
  -n com.example.ziweixingyu/com.ziweixingyu.ziweixingyu.MainActivity
```

## 2. 采一条真实输入

当前 APK 的输入页 `shuruye` 未导出，不能直接用 `am start` 跳到输入页，因此首选两条路径：

1. 盘面内手动导航并截图记录。
2. 读取应用私有 `shared_prefs`，冻结最近一次真实输入串。

当前已验证的输入来源：

- `/data/user/0/com.example.ziweixingyu/shared_prefs/lastsujipan.xml`
- `/data/user/0/com.example.ziweixingyu/shared_prefs/laststr1.xml`
- `/data/user/0/com.example.ziweixingyu/shared_prefs/jingdu.xml`
- `/data/user/0/com.example.ziweixingyu/shared_prefs/真太阳时.xml`

建议至少记录两类原始值：

- `input.apkRaw`：真正驱动 iOS 回归的 APK 参数串
- `source.apkClockRaw`：若同时能拿到北京时间参数串，也一并保留，便于后续追查

## 3. 从 APK UI 读取结果

- 读取页面以真实盘面页为准，例如当前样本来自 `com.ziweixingyu.ziweixingyu.ziweipan`
- 优先读取当前回归已覆盖的核心字段：
  - `命宫`
  - `身宫`
  - `命主`
  - `身主`
- 如果某字段没有稳定读取证据，不要猜；先省略该字段，后续补样本时再扩展

建议同步保存：

- 盘面截图
- 读取位置说明
- 任何需要人工判断的备注

## 4. 写成 fixture JSON

当前 fixture 契约由 `ZiWeiDoushuDianLiangXingKongTests/Support/APKBaselineCase.swift` 定义，最小结构如下：

```json
{
  "id": "core-fields-smoke",
  "input": {
    "apkRaw": "圻拆祗柝袛祇#2|2026|03|27|22|34|24|120.000000|-8|1|0"
  },
  "expected": {
    "global": {
      "mingGong": "辰",
      "shenGong": "寅",
      "mingZhu": "廉贞",
      "shenZhu": "铃星"
    },
    "palaces": []
  },
  "source": {
    "apkClockRaw": "圻拆祗柝袛祇#1|2026|3|27|22|39|43|120.0|-8|1|0",
    "documents": [
      "docs/apk-baselines/runtime-setup.md",
      "docs/apk-baselines/apk-source-log.md"
    ],
    "notes": [
      "2026-03-27 真实 APK 样本。",
      "字段由 ziweipan 页面截图人工读取。"
    ]
  }
}
```

## 5. 填写规则

- `id`：稳定、可读、可扩展，建议使用 `*-smoke`、`*-boundary-*` 这类命名
- `expected.global`：只填已经从 APK 明确确认过的字段
- `expected.palaces`：当前未核实宫位细节时保持 `[]`
- `source.documents`：至少链接到本次采集相关文档
- `source.notes`：记录读取方式、截图来源、人工判断口径、可信度说明

## 6. 采集后验证

新增或修改 fixture 后，先跑 APK 基线回归脚本：

```bash
./scripts/run-apk-baseline-tests.sh
```

如本机模拟器名称与默认值不同，可临时覆盖：

```bash
APK_BASELINE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=26.4" \
  ./scripts/run-apk-baseline-tests.sh
```

如果回归失败：

- 先核对 `input.apkRaw` 是否来自真实 APK
- 再核对 `expected` 是否只包含已确认字段
- 最后再看 iOS 输出是否真的发生了回归

## 7. 当前建议

- 首批样本先维持“小而真”：每条 fixture 只覆盖已经被 APK 证实的字段
- 等输入页自动化链路稳定后，再逐步补 `大限方向`、`四化`、`主星落宫` 等更丰富样本
