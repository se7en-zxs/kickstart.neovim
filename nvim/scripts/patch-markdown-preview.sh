#!/usr/bin/env bash
#
# markdown-preview.nvim 预览页 zoom 增强：把 JS 注入到插件目录
#
# 用途：
#   把一个自带的"点击图片/流程图弹层放大查看（滚轮缩放 + 拖拽平移）"脚本
#   注入到 markdown-preview.nvim 的预览页中。
#
# 插件本身不支持追加 CSS / JS（见插件 app/routes.js，只允许整体替换 markdown.css），
# 因此以"修改插件安装目录"的方式实现：
#   1. 把 配置目录/markdown-preview-zoom.js 复制为 插件目录/app/_static/mkdp-zoom.js
#   2. 在 插件目录/app/out/index.html 的 </body> 前，注入
#      <script src="/_static/mkdp-zoom.js">（幂等：已存在则跳过）
#
# 代码是幂等的，重复执行安全：
#   - 复制 JS 每次执行；
#   - 注入 script 用"是否已含 /_static/mkdp-zoom.js"判断，已含则跳过。
#
# 它会作为该插件的 lazy.nvim build 命令在插件 安装/更新 后自动调用一次；
# 也可手动重新调用（例如改了 JS 后）：
#   bash scripts/patch-markdown-preview.sh
#
# 依赖：bash、python3（仅用于往 index.html 注入一行）。
set -euo pipefail

# ---------- 定位目录 ----------
# 本脚本位于 配置目录/scripts/ 下（仓库 nvim/ 被软链为 ~/.config/nvim，或复制过去）。
# 因此配置目录 = 脚本目录的上一级，用真实路径解析，软链/复制两种部署都正确。
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CFG_DIR="$(dirname "$SCRIPT_DIR")"
# 插件数据目录 = ~/.local/share/nvim（可用 MKDP_PLUGIN_DIR 覆盖）
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
PLUGIN_DIR="${MKDP_PLUGIN_DIR:-$DATA_DIR/lazy/markdown-preview.nvim}"

SRC_JS="$CFG_DIR/markdown-preview-zoom.js"
DEST_JS="$PLUGIN_DIR/app/_static/mkdp-zoom.js"
INDEX="$PLUGIN_DIR/app/out/index.html"

if [ ! -f "$SRC_JS" ]; then
  echo "跳过：找不到 $SRC_JS" >&2
  exit 0
fi
if [ ! -f "$INDEX" ]; then
  echo "跳过：找不到预览页 $INDEX（插件未安装？）" >&2
  exit 0
fi

# ---------- 1. 复制 JS 到插件静态目录 ----------
mkdir -p "$(dirname "$DEST_JS")"
cp "$SRC_JS" "$DEST_JS"
echo "已写入 $DEST_JS"

# ---------- 2. 在 </body> 前注入 script（幂等） ----------
MARKER='/_static/mkdp-zoom.js'
if grep -qF "$MARKER" "$INDEX"; then
  echo "预览页已包含 $MARKER，跳过注入。"
else
  python3 - "$INDEX" <<'PY'
import sys
path = sys.argv[1]
tag = '<script src="/_static/mkdp-zoom.js"></script>'
with open(path, "r", encoding="utf-8", errors="ignore") as f:
    html = f.read()
taget = "</body>"
if taget not in html:
    # 极少数情况下没有 </body>，则追加到末尾
    html = html + "\n" + tag
else:
    html = html.replace(taget, tag + taget, 1)
with open(path, "w", encoding="utf-8") as f:
    f.write(html)
print("已在 " + path + " 注入 " + tag)
PY
fi

echo "markdown-preview zoom 增强注入完成。"