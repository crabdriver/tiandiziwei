#!/usr/bin/env bash
# 在仓库根目录执行：运行 APK 基线回归相关测试切片
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="${APK_BASELINE_PROJECT:-ZiWeiDoushuDianLiangXingKong.xcodeproj}"
SCHEME="${APK_BASELINE_SCHEME:-ZiWeiDoushuDianLiangXingKong}"
DESTINATION="${APK_BASELINE_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.4}"

echo "项目: $PROJECT"
echo "Scheme: $SCHEME"
echo "Destination: $DESTINATION"

xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineLoaderTests \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/ZiWeiChartComparableSnapshotTests \
  -only-testing:ZiWeiDoushuDianLiangXingKongTests/APKBaselineRegressionTests
