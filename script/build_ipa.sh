#!/bin/bash
# 将 Flutter 项目打包为 iOS IPA（Release）
# 用法: bash script/build_ipa.sh
# 要求: macOS、Xcode、CocoaPods、已在 Xcode 中配置好签名团队

set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/_common.sh"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "错误: IPA 只能在 macOS 上构建"
  exit 1
fi

ensure_flutter

if ! command -v pod >/dev/null 2>&1; then
  echo "错误: 未找到 pod (CocoaPods)"
  echo "可执行: bash scripts/fix_cocoapods.sh"
  exit 1
fi

# 确保 GUI / 精简 PATH 下也能调用 pod
export LANG="${LANG:-en_US.UTF-8}"
export GEM_HOME="${GEM_HOME:-${HOME}/.gem/ruby/2.6.0}"
export GEM_PATH="${GEM_PATH:-${GEM_HOME}:/Library/Ruby/Gems/2.6.0:/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/gems/2.6.0}"

prepare_flutter

VERSION=$(get_version)
echo ">> 版本: ${VERSION}"
echo ">> 安装 iOS 依赖 (pod install)..."

cd "${PROJECT_ROOT}/ios"
pod install
cd "${PROJECT_ROOT}"

echo ">> 开始构建 IPA (release)..."
echo ">> 请确保 Xcode 中 Runner 已配置有效的 Signing Team (当前: NYZNM362DP)"

flutter build ipa --release

IPA_PATH=$(find "${PROJECT_ROOT}/build/ios/ipa" -name "*.ipa" -print -quit 2>/dev/null || true)

if [[ -z "${IPA_PATH}" || ! -f "${IPA_PATH}" ]]; then
  echo "错误: 未在 build/ios/ipa/ 下找到 IPA"
  echo "若签名失败，请用 Xcode 打开 ios/Runner.xcworkspace 检查 Signing & Capabilities"
  exit 1
fi

copy_artifact "${IPA_PATH}" "stocknews-${VERSION}.ipa"

echo ""
echo "提示:"
echo "  - 个人免费开发者账号导出的 IPA 仅用于真机测试，无法上架 App Store"
echo "  - 上架请使用付费 Apple Developer 账号，并通过 Xcode Organizer 或 Transporter 上传"
