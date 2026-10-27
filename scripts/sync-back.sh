#!/usr/bin/env bash
#
# 把 ~/.config/nvim 的改动同步回本仓库的 nvim/ 目录。
# 仅在使用 --copy 模式安装时需要；--link 模式下 ~/.config/nvim 本身就是
# 仓库里的 nvim/，直接 git commit 即可。
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${NVIM_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/nvim}"

if [[ -L "$CONFIG_DIR" ]]; then
  echo "当前是软链接模式：$CONFIG_DIR -> $(readlink -f "$CONFIG_DIR")"
  echo "改动已经在仓库中，无需同步，直接 git commit 即可。"
  exit 0
fi

if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "找不到配置目录：$CONFIG_DIR" >&2
  exit 1
fi

command -v rsync >/dev/null 2>&1 || {
  echo "需要 rsync，请先安装（sudo apt install rsync）" >&2
  exit 1
}

echo "==> 同步 $CONFIG_DIR -> $REPO_DIR/nvim"
rsync -a --delete --exclude '.git' "$CONFIG_DIR/" "$REPO_DIR/nvim/"

echo
echo "同步完成。当前仓库状态："
git -C "$REPO_DIR" status --short
echo
echo "确认无误后提交："
echo "  git -C \"$REPO_DIR\" add -A && git -C \"$REPO_DIR\" commit -m \"chore: 同步 Neovim 配置\" && git -C \"$REPO_DIR\" push"
