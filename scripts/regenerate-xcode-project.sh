#!/usr/bin/env bash
# 在仓库根目录执行：根据 project.yml 重新生成 Xcode 工程
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "未找到 xcodegen。请先安装：brew install xcodegen" >&2
  exit 1
fi
xcodegen generate --spec project.yml
echo "已生成: ZiWeiDoushuDianLiangXingKong.xcodeproj"
