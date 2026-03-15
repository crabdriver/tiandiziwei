# 紫微星语 iOS

`紫微星语` 是一个基于 SwiftUI 的 iOS 紫微斗数排盘项目，当前仓库重点在于让 iOS 版的核心排盘结果尽量对齐既有 Android APK 的实际行为。

## 项目结构

- `ziwei/`: 应用源码
- `ziwei.xcodeproj/`: Xcode 工程
- `project.yml`: 项目配置

## 当前重点

- 紫微斗数核心排盘引擎
- 农历/干支/真太阳时相关计算
- 命盘展示与输入界面
- 针对 APK 样本的回归对齐

## 开发环境

- Xcode
- iOS 16.0+
- Swift 5.9

## 运行方式

1. 用 Xcode 打开 `ziwei.xcodeproj`
2. 选择模拟器或真机
3. 运行 `ziwei` target

## 说明

当前仓库已包含一轮针对 APK 行为的排盘逻辑校准。如果后续继续补齐杂曜、亮度或更多原始规则，建议以现有样本做回归校验后再提交。
