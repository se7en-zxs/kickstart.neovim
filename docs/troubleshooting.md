# 常见问题排查

按现象查：

- [图标显示为方块 / 问号](#图标显示为方块)
- [中文乱码 / 中文显示不全](#中文乱码)
- [E197: Cannot set language](#e197-cannot-set-language)
- [git 代理导致 GnuTLS 握手失败](#git-代理导致-gnutls-握手失败)
- [插件安装失败 / 卡住](#插件安装失败)
- [Treesitter 报错或没有高亮](#treesitter-报错或没有高亮)
- [系统剪贴板不可用](#系统剪贴板不可用)
- [checkhealth 一堆红色错误](#checkhealth-一堆红色错误)
- [启动变慢](#启动变慢)
- [想回到安装前](#想回到安装前)

---

## 图标显示为方块

**现象**：dashboard、文件树、状态栏里出现 `□`、`?` 或空白。

**原因**：终端字体没有 Nerd Font 字形。

本仓库安装脚本会安装 `Symbols Nerd Font Mono` 到
`~/.local/share/fonts/SymbolsNerdFontMono-Regular.ttf`，但**终端本身仍需配置字体回退**。

检查：

```bash
fc-list | grep -i "Symbols Nerd"
```

有输出说明字体已装。然后：

- **GNOME Terminal / Tilix**：首选项 → 字体 → 选择带 Nerd Font 的字体（如 `JetBrainsMono Nerd Font`），
  或确保字体回退可用
- **kitty**：`~/.config/kitty/kitty.conf`
  ```conf
  font_family JetBrainsMono Nerd Font
  ```
- **wezterm**：`~/.config/wezterm/wezterm.lua`
  ```lua
  config.font = wezterm.font("JetBrainsMono Nerd Font")
  ```
- **VS Code 终端**：设置 `terminal.integrated.fontFamily`

没有 Nerd Font 时也可以临时关掉图标，但 LazyVim 默认强依赖图标，不建议。

---

## 中文乱码

**现象**：打开 GBK/GB18030 文件显示乱码；或中文宽度错位。

本仓库已设置：

```lua
vim.opt.fileencodings = "ucs-bom,utf-8,gb18030,gbk,big5,latin1"
```

仍乱码时：

```vim
:e ++enc=gb18030
:e ++enc=gbk
```

确认终端 locale：

```bash
locale
echo $LANG
```

建议 `LANG=zh_CN.UTF-8` 或 `en_US.UTF-8`，两者都能正常显示中文。

**中文宽度错位**（中文占 1 格或 emoji 占 2 格）通常与终端/字体有关，
不要随意设 `ambiwidth=double`，它会让图标宽度异常。

---

## E197: Cannot set language

```text
E197: Cannot set language to "zh_CN"
```

三种原因：

1. 系统没有该 locale
   ```bash
   locale -a | grep -i zh
   ```
   没有 `zh_CN.utf8` 时：
   ```bash
   sudo locale-gen zh_CN.UTF-8
   sudo update-locale
   ```
2. `nvim.mo` 不在正确位置
   ```bash
   find ~/.local/opt/nvim-* -name nvim.mo
   ```
   应在 `<prefix>/share/locale/zh_CN*/LC_MESSAGES/nvim.mo`
3. 用了错误的 locale 名：配置会依次尝试 `zh_CN.utf8`、`zh_CN.UTF-8`、`zh_CN`

验证：

```bash
LANGUAGE=zh_CN.utf8 nvim --headless -u NONE \
  -c 'language zh_CN.utf8' \
  -c 'lua print(vim.fn.gettext("E492: Not an editor command"))' \
  -c 'qa!'
```

---

## git 代理导致 GnuTLS 握手失败

**现象**：`:Lazy sync` 时大量：

```text
fatal: 无法访问 'https://github.com/...'：
GnuTLS, handshake failed: The TLS connection was non-properly terminated.
```

但 `curl https://github.com` 正常。

**原因**：本机 `https_proxy` 指向的代理（如 Clash 的 7890 端口）与 git 使用的
GnuTLS 组合存在兼容问题；curl 用 OpenSSL，所以看起来“网络没问题”。

**处理**（任选）：

1. 让 git 绕过代理：
   ```bash
   unset https_proxy HTTPS_PROXY http_proxy HTTP_PROXY ALL_PROXY all_proxy
   nvim --headless "+Lazy! sync" "+qa"
   ```
2. 安装脚本已内置重试：默认先直连、再走代理：
   ```bash
   bash scripts/install.sh                 # auto
   NVIM_GIT_MODE=direct bash scripts/install.sh
   ```
3. 只对 GitHub 绕过代理（curl 支持 `no_proxy`，git 不一定，仅作备选）：
   ```bash
   export no_proxy="github.com,raw.githubusercontent.com,codeload.github.com,objects.githubusercontent.com,api.github.com"
   ```
4. 换代理协议或端口（例如 Clash 的 TUN 模式、SOCKS5），或临时关闭代理。

**长期建议**：在 shell 配置里按需设置代理，不要把会破坏 git 的代理变量无脑全局导出。

---

## 插件安装失败

**现象**：启动提示 `Plugin xxx is not installed`、`Too many rounds of missing plugins`。

处理顺序：

1. 看日志：
   ```vim
   :Lazy
   ```
   按 `L` 查看日志。
2. 重试同步：
   ```bash
   nvim --headless "+Lazy! sync" "+qa"
   ```
3. 网络问题按上一节处理代理。
4. 清理半成品再装：
   ```bash
   rm -rf ~/.local/share/nvim/lazy/*.cloning
   nvim --headless "+Lazy! sync" "+qa"
   ```
5. 仍失败时，确认这些目录可写：
   ```bash
   ls -ld ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
   ```

---

## Treesitter 报错或没有高亮

**现象**：

```text
`tree-sitter (CLI)` is not installed
```

或打开文件没有语法高亮。

安装 CLI：

```bash
npm install -g tree-sitter-cli
tree-sitter --version
```

安装解析器：

```bash
cd ~/.config/nvim
nvim --headless "+luafile scripts/treesitter-install.lua" "+qa!"
```

或在 nvim 中：

```vim
:TSUpdate
:TSInstall python lua bash json yaml
```

还依赖：

- `C compiler`（gcc/clang）
- `curl`、`tar`

解析器编译需要几十秒到几分钟。`python` 等语言第一次打开时也可能触发安装。

---

## 系统剪贴板不可用

```vim
:checkhealth clipboard
```

Linux 需要：

```bash
# X11
sudo apt install xclip
# Wayland
sudo apt install wl-clipboard
```

没有 sudo 时，可以在终端里用鼠标选中复制，或安装用户级工具后重试。

---

## checkhealth 一堆红色错误

常见“假阳性”：

| 报错 | 说明 |
|---|---|
| `Snacks.* setup did not run` | 在 headless 下检查，实际 TUI 正常 |
| `vim.ui.select is not set` | 同上，插件加载顺序问题 |
| `terminal does not support kitty graphics protocol` | 终端不支持图片协议，不影响编辑 |
| `tectonic / pdflatex not found` | 只在渲染 LaTeX 图片时需要 |
| `mmdc not found` | 只在渲染 Mermaid 时需要 |
| `luarocks not installed` | 已通过 `rocks.enabled = false` 关闭 |
| `fzf is not installed` | LazyVim 只是提示；默认 Snacks picker 不依赖 fzf |

判断标准：**在真实 TUI 中功能正常** 即可。重点看 `lazyvim` 与 `lazy` 两节的红色错误。

---

## 启动变慢

```vim
:Lazy profile
```

常见原因：

- 首次安装插件 / 解析器
- `checker.enabled = true` 在后台检查更新（不影响启动，但会联网）
- 某个插件没有懒加载

关闭更新检查（可选，编辑 `nvim/lua/config/lazy.lua`）：

```lua
checker = { enabled = false },
```

---

## 想回到安装前

```bash
ls -d ~/.config/nvim.bak.*
rm -f ~/.config/nvim                 # 如果是软链接
mv ~/.config/nvim.bak.20261027-210000 ~/.config/nvim
```

如果连 Neovim 也想清掉：

```bash
bash scripts/uninstall.sh --purge
```

---

## 仍然解决不了

收集以下信息再排查：

```bash
nvim --version
uname -a
locale
echo "proxy: $https_proxy"
nvim --headless "+checkhealth" "+w! /tmp/health.txt" "+qa"
```

`/tmp/health.txt` 里通常能直接看到根因。
