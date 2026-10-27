#!/usr/bin/env bash
#
# 卸载 kickstart.neovim 安装的内容（保守模式）。
#   * 只删除本脚本创建的软链接，不会删除真实配置目录
#   * 备份目录（~/.config/nvim.bak.*）永远保留
#
# 用法：
#   bash scripts/uninstall.sh           # 移除 nvim 软链与配置软链
#   bash scripts/uninstall.sh --purge   # 额外删除 Neovim 本体与插件数据
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_PREFIX="${NVIM_PREFIX:-$HOME/.local/opt}"
NVIM_BIN_DIR="${NVIM_BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${NVIM_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/nvim}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
PURGE=0

[[ "${1:-}" == "--purge" ]] && PURGE=1

echo "==> 卸载 kickstart.neovim"
echo "    配置目录: $CONFIG_DIR"

if [[ -L "$CONFIG_DIR" ]] && [[ "$(readlink -f "$CONFIG_DIR")" == "$(readlink -f "$REPO_DIR/nvim")" ]]; then
  rm -f "$CONFIG_DIR"
  echo "  ✓ 已移除配置软链接"
elif [[ -L "$CONFIG_DIR" ]]; then
  echo "  ! 配置目录是其他软链接，保留：$CONFIG_DIR -> $(readlink -f "$CONFIG_DIR")"
else
  echo "  ! 配置目录不是本仓库的软链接，保留（如有备份请自行恢复）"
fi

if [[ -L "$NVIM_BIN_DIR/nvim" ]]; then
  target="$(readlink -f "$NVIM_BIN_DIR/nvim")"
  case "$target" in
    "$(readlink -f "$NVIM_PREFIX")"/*)
      rm -f "$NVIM_BIN_DIR/nvim"
      echo "  ✓ 已移除 $NVIM_BIN_DIR/nvim"
      ;;
    *) echo "  ! $NVIM_BIN_DIR/nvim 指向其他位置，保留：$target" ;;
  esac
else
  echo "  ! $NVIM_BIN_DIR/nvim 不是本脚本创建的软链接，保留"
fi

if [[ $PURGE -eq 1 ]]; then
  read -r -p "确认删除 Neovim 本体与所有插件数据？[y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    rm -rf "$NVIM_PREFIX"/nvim "$NVIM_PREFIX"/nvim-*
    rm -rf "$DATA_DIR" "$STATE_DIR" "$CACHE_DIR"
    echo "  ✓ 已删除 Neovim 本体、插件数据与缓存"
  else
    echo "  已取消删除"
  fi
fi

cat <<EOF

完成。若需恢复旧配置：
  ls -d "$CONFIG_DIR".bak.* 2>/dev/null
  mv "$CONFIG_DIR".bak.YYYYmmdd-HHMMSS "$CONFIG_DIR"
EOF
