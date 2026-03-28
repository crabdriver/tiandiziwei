# APK 基线运行环境（实测记录）

本文档依据 **2026-03-27** 在本机一次真实探测结果填写；本次已完成 `adb` 安装、AVD 创建、APK 安装与一次真实盘面采样，以下内容均来自实测结果。

## 机器架构

| 项 | 实测值 |
|----|--------|
| `uname -m` | `arm64` |

## APK 位置与校验

| 项 | 值 |
|----|-----|
| 绝对路径 | `/Users/wizard/work_2025/tiandiziwei/app.apk` |
| 相对本 worktree 根目录 | `../../app.apk`（worktree 位于主仓库下的 `.worktrees/apk-baseline-execution/`） |
| Git | `app.apk` 由仓库根目录 `.gitignore` 规则 `/app.apk` 忽略，**为本地保留文件，不纳入版本控制**；各 clone/worktree 需自行放置同名文件或调整路径。 |
| SHA256 | `c8a8aa581993061676545e4e4f31ce7c1158b08a5a6b237145ac3812fdc5e34b` |
| 文件大小（实测） | 95301425 字节；修改时间（`stat`）2026-03-14 00:11:13 +0800（本地元数据，非发布证明） |

## Android 运行路径探测结果

| 检查项 | 结果 |
|--------|------|
| `adb` | 已通过 `brew install --cask android-platform-tools` 安装，版本 `36.0.2` |
| `sdkmanager` / `avdmanager` | 已通过 `brew install --cask android-commandlinetools` 安装 |
| Java | 系统已有可用 OpenJDK（`java -version` 返回 `23.0.1`） |
| `ANDROID_SDK_ROOT` | 本轮实测使用 `/opt/homebrew/share/android-commandlinetools` |
| SDK 关键包 | 已安装 `platform-tools`、`emulator`、`platforms;android-35`、`system-images;android-35;google_apis;arm64-v8a` |
| `emulator` 可执行文件 | `/opt/homebrew/share/android-commandlinetools/emulator/emulator` |

## 已验证的最小可运行路径

### 1. 创建并启动 AVD

- AVD 名称：`tiandiziwei-api35`
- Device profile：`pixel_8`
- System image：`system-images;android-35;google_apis;arm64-v8a`

实测启动命令：

```bash
ANDROID_SDK_ROOT=/opt/homebrew/share/android-commandlinetools \
  /opt/homebrew/share/android-commandlinetools/emulator/emulator \
  -avd tiandiziwei-api35 \
  -no-snapshot-save
```

### 2. 设备可见性

实测命令：

```bash
adb devices
adb -s emulator-5554 shell getprop sys.boot_completed
```

实测结果：

- `adb devices` 返回 `emulator-5554	device`
- `getprop sys.boot_completed` 返回 `1`

### 3. APK 安装

实测命令：

```bash
adb -s emulator-5554 install -r /Users/wizard/work_2025/tiandiziwei/app.apk
```

实测结果：

```text
Performing Streamed Install
Success
```

### 4. 启动与到达排盘界面

已确认：

- 包名：`com.example.ziweixingyu`
- launcher activity：`com.ziweixingyu.ziweixingyu.MainActivity`
- 当前盘面 activity：`com.ziweixingyu.ziweixingyu.ziweipan`

实测启动命令：

```bash
adb -s emulator-5554 shell am start \
  -n com.example.ziweixingyu/com.ziweixingyu.ziweixingyu.MainActivity
```

实测结果：应用可启动，并进入 `ziweipan` 盘面页。

## 首个真实 APK 样本（Task 1 Step 5）

### 输入来源

- 精确输入串来自模拟器内应用偏好文件：
  - `/data/user/0/com.example.ziweixingyu/shared_prefs/lastsujipan.xml`
  - `/data/user/0/com.example.ziweixingyu/shared_prefs/laststr1.xml`
  - `/data/user/0/com.example.ziweixingyu/shared_prefs/jingdu.xml`
  - `/data/user/0/com.example.ziweixingyu/shared_prefs/真太阳时.xml`
- 盘面结果来自 `ziweipan` 页面真实屏幕截图（`uiautomator` 只能看到单个自定义 View，文字需从截图人工读取）

### 精确输入

- 真太阳时参数串：`圻拆祗柝袛祇#2|2026|03|27|22|34|24|120.000000|-8|1|0`
- 对应北京时间参数串：`圻拆祗柝袛祇#1|2026|3|27|22|39|43|120.0|-8|1|0`
- 可直接确认的字段：
  - 时间模式：`2`（真太阳时）
  - 真太阳时：`2026-03-27 22:34:24`
  - 北京时间：`2026-03-27 22:39:43`
  - 经度：`120.0`
  - 时区：`-8`
  - 性别代码：`1`
  - 换月：`0`

### 从 APK UI 读取到的首批结果字段

- 读取页面：`com.ziweixingyu.ziweixingyu.ziweipan`
- 读取方式：
  - `命宫` 来自左侧高亮宫标题，读为 `辰`
  - `身宫` 来自盘面中央摘要，读为 `寅`
  - 额外核心字段取 `命主 / 身主`
- 当前样本可确认：
  - `命宫 = 辰`
  - `身宫 = 寅`
  - `命主 = 廉贞`
  - `身主 = 铃星`

## 当前剩余 Blocker

- **仍存在的 blocker：** 虽然 APK 已安装并能打开盘面，但输入页 `shuruye` 未导出，不能从 shell 直接 `am start`，后续若要批量采样，仍需补一条稳定的“盘面内导航到输入页”操作链路，或继续从应用私有数据读取最近一次输入串。

## 下一步

基于本轮已确认的真实运行链路，下一步可以直接把上述样本整理为 `core-fields-smoke.json`，并在 `Task 2` 中实现 fixture loader。
