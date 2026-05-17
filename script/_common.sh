#!/bin/bash
# 打包脚本公共函数（由 build_apk.sh / build_ipa.sh 引用）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/script/output"

get_version() {
  local version_line
  version_line=$(grep -E '^version:' "${PROJECT_ROOT}/pubspec.yaml" | head -1)
  echo "${version_line#version: }" | tr -d ' ' | tr '+' '-'
}

ensure_flutter() {
  if ! command -v flutter >/dev/null 2>&1; then
    echo "错误: 未找到 flutter，请先安装并加入 PATH"
    exit 1
  fi
}

prepare_flutter() {
  cd "${PROJECT_ROOT}"
  echo ">> flutter pub get"
  flutter pub get
}

copy_artifact() {
  local src="$1"
  local dest_name="$2"
  mkdir -p "${OUTPUT_DIR}"
  local dest="${OUTPUT_DIR}/${dest_name}"
  cp "${src}" "${dest}"
  echo ""
  echo "打包完成: ${dest}"
  ls -lh "${dest}"
}
