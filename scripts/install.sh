#!/usr/bin/env bash
#
# kickstart.neovim 一键安装脚本
#
# 功能：
#   1. 安装官方 Neovim（默认自动解析 GitHub 最新 release）到 ~/.local/opt，
#      并软链到 ~/.local/bin/nvim
#   2. 编译并安装 Neovim 官方中文语言包（nvim.mo）
#   3. 把本仓库的 nvim/ 配置链接（默认）或复制到 ~/.config/nvim
#   4. 首次启动并安装 LazyVim 插件
#
# 用法：
#   bash scripts/install.sh                 # 默认：软链接配置（改动直接进仓库）
#   bash scripts/install.sh --copy          # 复制配置（改动用 sync-back.sh 同步回仓库）
#   bash scripts/install.sh --no-nvim       # 使用系统已有的 nvim，不安装官方版本
#   bash scripts/install.sh --force         # 强制重新下载 Neovim
#   bash scripts/install.sh --version v0.11.6   # 手动指定版本（缺省自动用最新）
#
# 可用环境变量：
#   NVIM_VERSION        Neovim 版本（缺省自动解析 GitHub 最新 release）
#   NVIM_TARBALL_URL    自定义下载地址
#   NVIM_PO_URL         自定义中文 .po 地址
#   NVIM_PREFIX         安装前缀（默认 ~/.local/opt）
#   NVIM_BIN_DIR        可执行文件目录（默认 ~/.local/bin）
#   NVIM_CONFIG_DIR     配置目录（默认 ~/.config/nvim）
#   CONFIG_MODE         link 或 copy（默认 link）
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# 默认 v0.12.6 的历史固定版本被移除：不指定版本时自动解析 GitHub 最新 release（见 resolve_latest_version）。
NVIM_VERSION="${NVIM_VERSION:-}"
NVIM_PREFIX="${NVIM_PREFIX:-$HOME/.local/opt}"
NVIM_BIN_DIR="${NVIM_BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${NVIM_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/nvim}"
CONFIG_MODE="${CONFIG_MODE:-link}"
INSTALL_NVIM=1
INSTALL_TOOLS=1
INSTALL_TS=1
FORCE=0

# GitHub 相关域名：部分代理会让 git 的 GnuTLS 握手失败，安装时会尝试绕过
GH_HOSTS="github.com,raw.githubusercontent.com,codeload.github.com,objects.githubusercontent.com,api.github.com"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2
  exit 1
}

# 下载文件；失败时尝试让 GitHub 域名绕过代理再试一次
fetch() {
  local url="$1" dest="$2"
  if curl -fL --retry 3 --connect-timeout 15 -o "$dest" "$url"; then
    return 0
  fi
  warn "通过当前代理下载失败，尝试直连 GitHub……"
  env no_proxy="$GH_HOSTS" NO_PROXY="$GH_HOSTS" \
    curl -fL --retry 3 --connect-timeout 15 -o "$dest" "$url"
}

# 解析 Neovim 最新 release 版本号（如 v0.12.6）。
# 通过“latest 重定向”的 Location 头拿 tag，最可靠且不需要 GitHub API/jq。
# 与 fetch() 一样：先按当前代理，失败后尝试绕过代理直连 GitHub。
resolve_latest_version() {
  local loc ver url="https://github.com/neovim/neovim/releases/latest"
  loc="$(curl -fsSI --connect-timeout 15 "$url" \
    | awk 'tolower($1)=="location:"{print $2}')"
  ver="$(sed -E 's#.*/tag/([^/\r\n]+).*#\1#' <<<"$loc")"
  if ! [[ "$ver" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    warn "通过当前代理获取最新版失败，尝试直连 GitHub……"
    loc="$(env no_proxy="$GH_HOSTS" NO_PROXY="$GH_HOSTS" \
      curl -fsSI --connect-timeout 15 "$url" \
      | awk 'tolower($1)=="location:"{print $2}')"
    ver="$(sed -E 's#.*/tag/([^/\r\n]+).*#\1#' <<<"$loc")"
  fi
  # 个别代理 / CDN 拿不到 Location，退回 GitHub API（仅此一处依赖 API，无需 jq）
  if ! [[ "$ver" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ver="$(curl -fsSL --connect-timeout 15 \
      https://api.github.com/repos/neovim/neovim/releases/latest \
      | awk -F'"' '/"tag_name"/{print $4; exit}')"
  fi
  printf '%s' "$ver"
}

# 请求一次能拿到的 Neovim 版本；既没传版本也没解析成功时给出清晰报错
ensure_nvim_version() {
  if [[ -z "$NVIM_VERSION" ]]; then
    local latest
    log "解析 Neovim 最新 release 版本……"
    latest="$(resolve_latest_version)" || true
    if [[ -n "$latest" ]]; then
      NVIM_VERSION="$latest"
      ok "最新 Neovim 版本：$latest"
    else
      die "无法获取 Neovim 最新版本（网络受限）。
可手动指定版本重试，例如：bash scripts/install.sh --version v0.12.6"
    fi
  fi
}

usage() {
  cat <<'EOF'
用法：
  bash scripts/install.sh                 默认：软链接配置（改动直接进仓库）
  bash scripts/install.sh --copy          复制配置（改动用 sync-back.sh 同步回仓库）
  bash scripts/install.sh --no-nvim       使用系统已有的 nvim，不安装官方版本
  bash scripts/install.sh --no-tools      不安装 ripgrep / fd / fzf / lazygit
  bash scripts/install.sh --no-treesitter 不预装 Treesitter 解析器
  bash scripts/install.sh --force         强制重新下载 Neovim 与工具
  bash scripts/install.sh --version v0.12.6   指定版本（不指定则自动用最新版）

环境变量：
  NVIM_VERSION        Neovim 版本（缺省自动解析 GitHub 最新 release）
  NVIM_TARBALL_URL    自定义 Neovim 下载地址
  NVIM_PO_URL         自定义中文 .po 地址
  NVIM_PREFIX         安装前缀（默认 ~/.local/opt）
  NVIM_BIN_DIR        可执行文件目录（默认 ~/.local/bin）
  NVIM_CONFIG_DIR     配置目录（默认 ~/.config/nvim）
  CONFIG_MODE         link 或 copy（默认 link）
  NVIM_GIT_MODE       auto（默认，直连失败后用代理）/ direct / proxy
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --link) CONFIG_MODE="link" ;;
    --copy) CONFIG_MODE="copy" ;;
    --no-nvim) INSTALL_NVIM=0 ;;
    --no-tools) INSTALL_TOOLS=0 ;;
    --no-treesitter) INSTALL_TS=0 ;;
    --force) FORCE=1 ;;
    --version)
      [[ $# -ge 2 ]] || die "--version 需要一个版本号，例如 v0.12.6"
      NVIM_VERSION="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "未知参数：$1（使用 --help 查看用法）" ;;
  esac
  shift
done

[[ "$(id -u)" -ne 0 ]] || die "请用普通用户运行，不要使用 root 或 sudo。"

# 不指定版本时，先解析 GitHub 最新 release；解析成功后才继续
ensure_nvim_version

NVIM_VERSION="v${NVIM_VERSION#v}"
NVIM_DIR="$NVIM_PREFIX/nvim-${NVIM_VERSION#v}"
NVIM_BIN="$NVIM_BIN_DIR/nvim"
[[ "$CONFIG_MODE" == "link" || "$CONFIG_MODE" == "copy" ]] || die "CONFIG_MODE 只能是 link 或 copy"
for cmd in curl tar git; do
  command -v "$cmd" >/dev/null 2>&1 || die "缺少命令：$cmd"
done

# ---------------------------------------------------------------------------
# 1. 安装 Neovim
# ---------------------------------------------------------------------------
install_neovim() {
  local arch
  case "$(uname -m)" in
    x86_64 | amd64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) die "不支持的 CPU 架构：$(uname -m)" ;;
  esac

  if [[ -x "$NVIM_DIR/bin/nvim" && $FORCE -eq 0 ]]; then
    log "Neovim 已存在：$NVIM_DIR"
  else
    log "下载 Neovim $NVIM_VERSION（$(uname -m)）"
    local url="${NVIM_TARBALL_URL:-https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${arch}.tar.gz}"
    if ! fetch "$url" "$TMP_DIR/nvim.tar.gz"; then
      die "下载失败：$url
可以设置代理后重试，例如：
  https_proxy=http://127.0.0.1:7890 bash scripts/install.sh
或手动下载后通过 NVIM_TARBALL_URL=file:///path/to/nvim.tar.gz 指定。"
    fi

    log "解压到 $NVIM_DIR"
    rm -rf "$NVIM_DIR"
    mkdir -p "$NVIM_PREFIX"
    tar -xzf "$TMP_DIR/nvim.tar.gz" -C "$TMP_DIR"
    mv "$TMP_DIR/nvim-linux-${arch}" "$NVIM_DIR"
  fi

  mkdir -p "$NVIM_BIN_DIR"
  # 如果已有非本脚本管理的 nvim，先备份
  if [[ -e "$NVIM_BIN_DIR/nvim" && ! -L "$NVIM_BIN_DIR/nvim" ]]; then
    mv "$NVIM_BIN_DIR/nvim" "$NVIM_BIN_DIR/nvim.bak.$(date +%Y%m%d-%H%M%S)"
    warn "已备份原有的 $NVIM_BIN_DIR/nvim"
  fi
  ln -sfn "$NVIM_PREFIX/nvim-${NVIM_VERSION#v}" "$NVIM_PREFIX/nvim"
  ln -sfn "$NVIM_PREFIX/nvim/bin/nvim" "$NVIM_BIN"
  hash -r
  ok "$("$NVIM_BIN" --version | head -n 1)"
}

# ---------------------------------------------------------------------------
# 2. 安装中文语言包
# ---------------------------------------------------------------------------
install_locale() {
  command -v python3 >/dev/null 2>&1 || {
    warn "未找到 python3，跳过中文语言包（内置消息将保持英文）"
    return 0
  }

  log "安装 Neovim 中文语言包"
  local po_url="${NVIM_PO_URL:-https://raw.githubusercontent.com/neovim/neovim/${NVIM_VERSION}/src/nvim/po/zh_CN.UTF-8.po}"
  if ! fetch "$po_url" "$TMP_DIR/zh_CN.po"; then
    warn "无法下载中文翻译（$po_url），内置消息将保持英文"
    return 0
  fi

  if ! python3 "$REPO_DIR/scripts/po2mo.py" "$TMP_DIR/zh_CN.po" "$TMP_DIR/nvim.mo"; then
    warn "编译 nvim.mo 失败，内置消息将保持英文"
    return 0
  fi

  # glibc 在不同系统上可能使用 zh_CN 或 zh_CN.utf8，两个目录都放一份
  local locale
  for locale in zh_CN zh_CN.utf8; do
    install -Dm644 "$TMP_DIR/nvim.mo" "$NVIM_DIR/share/locale/$locale/LC_MESSAGES/nvim.mo"
  done

  local msg
  msg="$(LANGUAGE=zh_CN.utf8 "$NVIM_BIN" --headless -u NONE \
    -c 'language zh_CN.utf8' \
    -c 'lua print(vim.fn.gettext("E492: Not an editor command"))' \
    -c 'qa!' 2>&1 || true)"
  if [[ "$msg" == *"不是编辑器"* ]]; then
    ok "内置消息已汉化"
  else
    warn "语言包已安装，但当前系统可能未生成 zh_CN locale，内置消息仍为英文（$msg）"
  fi
}

# ---------------------------------------------------------------------------
# 3. 安装常用命令行工具（LazyVim 的查找/搜索依赖 rg 与 fd）
# ---------------------------------------------------------------------------
install_tool() {
  local name="$1" url="$2"
  if command -v "$name" >/dev/null 2>&1 && [[ $FORCE -eq 0 ]]; then
    ok "$name 已安装：$(command -v "$name")"
    return 0
  fi

  local dir="$TMP_DIR/tool-$name"
  mkdir -p "$dir"
  if ! fetch "$url" "$dir/pkg.tar.gz"; then
    warn "下载 $name 失败，跳过（可稍后手动安装）"
    return 0
  fi
  if ! tar -xzf "$dir/pkg.tar.gz" -C "$dir"; then
    warn "解压 $name 失败，跳过"
    return 0
  fi

  local bin
  bin="$(find "$dir" -type f -name "$name" -perm -u+x | head -n 1)"
  if [[ -z "$bin" ]]; then
    warn "压缩包里找不到 $name 可执行文件，跳过"
    return 0
  fi

  install -m755 "$bin" "$NVIM_BIN_DIR/$name"
  ok "$name：$("$NVIM_BIN_DIR/$name" --version 2>/dev/null | head -n 1)"
}

install_tools() {
  log "安装命令行工具（ripgrep / fd / fzf / lazygit）"
  mkdir -p "$NVIM_BIN_DIR"
  local mach rg_url fd_url lg_url fzf_url
  mach="$(uname -m)"
  case "$mach" in
    x86_64 | amd64)
      rg_url="https://github.com/BurntSushi/ripgrep/releases/download/15.2.0/ripgrep-15.2.0-x86_64-unknown-linux-musl.tar.gz"
      fd_url="https://github.com/sharkdp/fd/releases/download/v10.5.0/fd-v10.5.0-x86_64-unknown-linux-musl.tar.gz"
      lg_url="https://github.com/jesseduffield/lazygit/releases/download/v0.66.2/lazygit_0.66.2_linux_x86_64.tar.gz"
      fzf_url="https://github.com/junegunn/fzf/releases/download/v0.74.5/fzf-0.74.5-linux_amd64.tar.gz"
      ;;
    aarch64 | arm64)
      rg_url="https://github.com/BurntSushi/ripgrep/releases/download/15.2.0/ripgrep-15.2.0-aarch64-unknown-linux-gnu.tar.gz"
      fd_url="https://github.com/sharkdp/fd/releases/download/v10.5.0/fd-v10.5.0-aarch64-unknown-linux-musl.tar.gz"
      lg_url="https://github.com/jesseduffield/lazygit/releases/download/v0.66.2/lazygit_0.66.2_linux_arm64.tar.gz"
      fzf_url="https://github.com/junegunn/fzf/releases/download/v0.74.5/fzf-0.74.5-linux_arm64.tar.gz"
      ;;
    *)
      warn "未知架构 $mach，跳过工具安装"
      return 0
      ;;
  esac

  install_tool rg "$rg_url"
  install_tool fd "$fd_url"
  install_tool lazygit "$lg_url"
  install_tool fzf "$fzf_url"
}

# ---------------------------------------------------------------------------
# 4. 部署配置
# ---------------------------------------------------------------------------
backup_config() {
  local backup
  backup="${CONFIG_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
  mv "$CONFIG_DIR" "$backup"
  warn "原配置已备份到 $backup"
}

deploy_config() {
  log "部署配置到 $CONFIG_DIR（模式：$CONFIG_MODE）"
  mkdir -p "$(dirname "$CONFIG_DIR")"

  if [[ -L "$CONFIG_DIR" ]] && [[ "$(readlink -f "$CONFIG_DIR")" == "$(readlink -f "$REPO_DIR/nvim")" ]]; then
    ok "配置已软链接到 $REPO_DIR/nvim"
    return 0
  fi

  if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
    backup_config
  fi

  if [[ "$CONFIG_MODE" == "link" ]]; then
    ln -sfn "$REPO_DIR/nvim" "$CONFIG_DIR"
    ok "$CONFIG_DIR -> $REPO_DIR/nvim"
  else
    mkdir -p "$CONFIG_DIR"
    rsync -a "$REPO_DIR/nvim/" "$CONFIG_DIR/"
    ok "已复制配置（后续用 scripts/sync-back.sh 同步回仓库）"
  fi
}

# ---------------------------------------------------------------------------
# 5. 安装插件并验证
# ---------------------------------------------------------------------------
# 某些代理会让 git 的 GnuTLS 握手失败；网络也可能间歇性中断。
# 因此依次尝试“直连 / 代理”两种方式，并各重试两次。
run_sync() {
  local mode="$1"
  if [[ "$mode" == "direct" ]]; then
    env -u http_proxy -u https_proxy -u all_proxy \
      -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
      timeout 900 "$NVIM_BIN" --headless "+Lazy! sync" "+qa"
  else
    timeout 900 "$NVIM_BIN" --headless "+Lazy! sync" "+qa"
  fi
}

plugins_ok() {
  local out
  out="$("$NVIM_BIN" --headless "+lua print('CHECK_OK')" "+qa" 2>&1)" || return 1
  grep -q "CHECK_OK" <<<"$out" || return 1
  ! grep -qE 'is not installed|Too many rounds|Error in' <<<"$out"
}

bootstrap_plugins() {
  local -a modes=(direct proxy)
  case "${NVIM_GIT_MODE:-auto}" in
    direct) modes=(direct) ;;
    proxy) modes=(proxy) ;;
  esac

  local mode attempt
  for mode in "${modes[@]}"; do
    for attempt in 1 2; do
      log "安装 / 同步 LazyVim 插件（$mode，第 $attempt 次）"
      run_sync "$mode" || warn "本次同步未正常结束，继续检查……"
      if plugins_ok; then
        ok "插件安装完成"
        return 0
      fi
      warn "仍有插件缺失，重试……"
    done
  done

  die "插件未能全部安装。请检查网络或代理后重新运行本脚本，或在 nvim 中执行 :Lazy sync"
}

install_treesitter() {
  log "安装 Treesitter 解析器（首次需要下载并编译，可能较慢）"
  if ! command -v tree-sitter >/dev/null 2>&1; then
    if command -v npm >/dev/null 2>&1; then
      log "安装 tree-sitter CLI（npm）"
      npm install -g tree-sitter-cli >/dev/null 2>&1 || warn "tree-sitter CLI 安装失败"
    else
      warn "未找到 npm，无法自动安装 tree-sitter CLI"
    fi
  fi

  local script="$REPO_DIR/scripts/treesitter-install.lua"
  if [[ ! -f "$script" ]]; then
    warn "找不到 $script，跳过"
    return 0
  fi

  local mode
  for mode in direct proxy; do
    if [[ "$mode" == "direct" ]]; then
      if env -u http_proxy -u https_proxy -u all_proxy \
        -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
        timeout 900 "$NVIM_BIN" --headless "+luafile $script" "+qa!" >"$TMP_DIR/ts-$mode.log" 2>&1; then
        ok "Treesitter 解析器安装完成"
        return 0
      fi
    else
      if timeout 900 "$NVIM_BIN" --headless "+luafile $script" "+qa!" >"$TMP_DIR/ts-$mode.log" 2>&1; then
        ok "Treesitter 解析器安装完成"
        return 0
      fi
    fi
    warn "$mode 方式安装失败，继续尝试下一种方式……"
  done

  warn "部分解析器安装失败，可稍后在 nvim 中执行 :TSUpdate"
  tail -n 5 "$TMP_DIR/ts-proxy.log" 2>/dev/null | sed 's/^/      /' || true
}

verify() {
  log "验证配置"
  local out
  if ! out="$("$NVIM_BIN" --headless "+lua print('L10N=' .. tostring(vim.g.l10n_locale or 'none'))" "+qa" 2>&1)"; then
    printf '%s\n' "$out"
    die "Neovim 配置加载失败，请检查上面的报错。"
  fi
  printf '%s\n' "$out" | grep -q "L10N=" || die "配置未正常加载"
  if printf '%s\n' "$out" | grep -q "L10N=none"; then
    warn "中文语言包未生效（内置消息为英文），可查看 docs/troubleshooting.md"
  else
    ok "中文消息 locale：$(printf '%s\n' "$out" | sed -n 's/.*L10N=//p' | head -n 1)"
  fi

  if printf '%s\n' "$out" | grep -qE 'is not installed|Too many rounds|Error in'; then
    printf '%s\n' "$out"
    die "插件未完整安装，请检查网络后重新运行本脚本，或运行 nvim 执行 :Lazy sync"
  fi
}

[[ $INSTALL_NVIM -eq 1 ]] && install_neovim
if [[ $INSTALL_NVIM -eq 0 ]]; then
  command -v nvim >/dev/null 2>&1 || die "系统中没有 nvim，无法使用 --no-nvim"
  NVIM_BIN="$(command -v nvim)"
  log "使用系统 Neovim：$NVIM_BIN（$("$NVIM_BIN" --version | head -n 1)）"
  warn "跳过 Neovim 安装与中文语言包；若系统版未带 nvim.mo，内置消息会保持英文"
fi

[[ $INSTALL_NVIM -eq 1 ]] && install_locale
[[ $INSTALL_TOOLS -eq 1 ]] && install_tools
deploy_config
bootstrap_plugins
[[ $INSTALL_TS -eq 1 ]] && install_treesitter
verify

case ":$PATH:" in
  *":$NVIM_BIN_DIR:"*) ;;
  *) warn "$NVIM_BIN_DIR 不在 PATH 中，请把下面一行加入 ~/.bashrc：
      export PATH=\"$NVIM_BIN_DIR:\$PATH\"" ;;
esac

cat <<EOF

$(printf '\033[1;32m安装完成。\033[0m')

  Neovim   $("$NVIM_BIN" --version | head -n 1)
  配置     $CONFIG_DIR
  插件目录 ${XDG_DATA_HOME:-$HOME/.local/share}/nvim

下一步：
  1. 打开 nvim，等待首次加载完成
  2. :Lazy            查看 / 更新插件
  3. :checkhealth     检查环境（含 LazyVim 健康检查）
  4. <leader>uC       切换菜单中文 / English
  5. <leader>?        查看当前缓冲区可用键位

文档：README.md、docs/installation.md
EOF
