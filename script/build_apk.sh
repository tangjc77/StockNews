#!/bin/bash
# 将 Flutter 项目打包为 Android APK（Release）
# 用法: bash script/build_apk.sh
#       SPLIT_ABI=1 bash script/build_apk.sh   # 按 CPU 架构分包（体积更小）

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/_common.sh"

ensure_flutter
prepare_flutter

VERSION=$(get_version)
echo ">> 版本: ${VERSION}"
echo ">> 开始构建 APK (release)..."

BUILD_ARGS=(build apk --release)
if [[ "${SPLIT_ABI:-0}" == "1" ]]; then
  BUILD_ARGS+=(--split-per-abi)
  echo ">> 已启用按架构分包 (SPLIT_ABI=1)"
fi

flutter "${BUILD_ARGS[@]}"

if [[ "${SPLIT_ABI:-0}" == "1" ]]; then
  APK_DIR="${PROJECT_ROOT}/build/app/outputs/flutter-apk"
  mkdir -p "${OUTPUT_DIR}"
  for apk in "${APK_DIR}"/app-*-release.apk; do
    [[ -f "${apk}" ]] || continue
    abi=$(basename "${apk}" | sed 's/app-\(.*\)-release.apk/\1/')
    copy_artifact "${apk}" "stocknews-${VERSION}-${abi}.apk"
  done
else
  APK_PATH="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-release.apk"
  if [[ ! -f "${APK_PATH}" ]]; then
    echo "错误: 未找到 APK 文件 ${APK_PATH}"
    exit 1
  fi
  copy_artifact "${APK_PATH}" "stocknews-${VERSION}.apk"
fi

echo ""
echo "提示: 当前 Release 使用 debug 签名，上架应用商店前请在 android/app/build.gradle.kts 配置正式签名。"
