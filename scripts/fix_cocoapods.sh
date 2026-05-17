#!/bin/bash
# 修复 Android Studio / Flutter 在 GUI 环境下找不到可用 CocoaPods 的问题。
# 在终端执行: bash scripts/fix_cocoapods.sh

set -e

GEM_BIN="${HOME}/.gem/ruby/2.6.0/bin/pod"
if [ ! -x "$GEM_BIN" ]; then
  echo "未找到 ${GEM_BIN}，请先安装: gem install cocoapods"
  exit 1
fi

echo "将用可用的 pod 包装脚本替换 /usr/local/bin/pod（需要管理员密码）"
sudo tee /usr/local/bin/pod > /dev/null << EOF
#!/bin/bash
export LANG=en_US.UTF-8
export HOME="${HOME}"
export GEM_HOME="${HOME}/.gem/ruby/2.6.0"
export GEM_PATH="${HOME}/.gem/ruby/2.6.0:/Library/Ruby/Gems/2.6.0:/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/gems/2.6.0"
exec "${GEM_BIN}" "\$@"
EOF

sudo chmod +x /usr/local/bin/pod
Ï
echo "验证（模拟 Android Studio 的 PATH）..."
env -i PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin pod --version

echo "完成。请重启 Android Studio 后再次运行项目。"
