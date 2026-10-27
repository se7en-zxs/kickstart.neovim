# 安装总览

本文是 `kickstart.neovim` 的安装主文档：先给一键安装，再给可逐步审计的手动流程。

---

## 1. 前置条件

| 项目 | 要求 | 说明 |
|---|---|---|
| 系统 | Linux x86_64 / arm64 | 脚本按架构自动选择安装包；macOS 可参考手动步骤 |
| `git` | ≥ 2.19 | LazyVim 需要 partial clone |
| `curl` | 任意较新版本 | 下载 Neovim、语言包、工具 |
| `python3` | ≥ 3.9 | 编译 `.po` → `.mo`；不装则中文内置消息不可用 |
| 终端 | 支持真彩色与 UTF-8 | 推荐 kitty / wezterm / ghostty / GNOME Terminal |
| 字体 | Nerd Font（可选） | 用于文件图标；本仓库会安装 Symbols Nerd Font |

> 脚本**不需要 sudo**，所有内容都在 `$HOME` 下。

---

## 2. 一键安装

```bash
git clone https://github.com/se7en-zxs/kickstart.neovim.git
cd kickstart.neovim
bash scripts/install.sh
```

### 脚本做了什么

1. 下载 `nvim-linux-<arch>.tar.gz`（默认 v0.12.6）
2. 解压到 `~/.local/opt/nvim-0.12.6`，创建：
   - `~/.local/opt/nvim` → 版本目录
   - `~/.local/bin/nvim` → `~/.local/opt/nvim/bin/nvim`
3. 下载对应版本的 `zh_CN.UTF-8.po`，用 `scripts/po2mo.py` 编译并安装到
   `~/.local/opt/nvim-0.12.6/share/locale/{zh_CN,zh_CN.utf8}/LC_MESSAGES/nvim.mo`
4. 安装 `rg`、`fd`、`fzf`、`lazygit` 到 `~/.local/bin`
5. 安装 `tree-sitter` CLI（若系统有 npm）
6. 备份已有 `~/.config/nvim`，然后创建软链接：
   `~/.config/nvim` → 仓库的 `nvim/`
7. 执行 `nvim --headless "+Lazy! sync" +qa` 安装插件
8. 执行 `scripts/treesitter-install.lua` 预装解析器
9. 验证中文 locale 与配置加载

### 网络与代理

脚本会针对插件安装自动尝试两种方式：

1. **直连**（临时去掉 `http_proxy` 等变量）
2. **代理**（沿用当前 shell 的代理变量）

两种方式各重试两次仍失败时，会提示重新运行。也可以手动指定：

```bash
NVIM_GIT_MODE=direct bash scripts/install.sh   # 只用直连
NVIM_GIT_MODE=proxy  bash scripts/install.sh   # 只用代理
```

如果你遇到 `GnuTLS, handshake failed`，见 [troubleshooting.md](troubleshooting.md#git-代理导致-gnutls-握手失败)。

---

## 3. 手动安装（逐步）

不想运行脚本时，可以按下面的步骤自己做，效果一致。

### 3.1 安装 Neovim

```bash
mkdir -p ~/.local/opt ~/.local/bin
cd /tmp
curl -fLO https://github.com/neovim/neovim/releases/download/v0.12.6/nvim-linux-x86_64.tar.gz
tar xzf nvim-linux-x86_64.tar.gz -C ~/.local/opt
mv ~/.local/opt/nvim-linux-x86_64 ~/.local/opt/nvim-0.12.6
ln -sfn ~/.local/opt/nvim-0.12.6 ~/.local/opt/nvim
ln -sfn ~/.local/opt/nvim/bin/nvim ~/.local/bin/nvim
nvim --version
```

arm64 把 `x86_64` 换成 `arm64`。确认 `~/.local/bin` 在 `PATH` 中：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### 3.2 安装中文语言包

```bash
cd ~/path/to/kickstart.neovim
curl -fLO https://raw.githubusercontent.com/neovim/neovim/v0.12.6/src/nvim/po/zh_CN.UTF-8.po
python3 scripts/po2mo.py zh_CN.UTF-8.po /tmp/nvim.mo
for loc in zh_CN zh_CN.utf8; do
  install -Dm644 /tmp/nvim.mo \
    ~/.local/opt/nvim-0.12.6/share/locale/$loc/LC_MESSAGES/nvim.mo
done
```

验证：

```bash
LANGUAGE=zh_CN.utf8 nvim --headless -u NONE \
  -c 'language zh_CN.utf8' \
  -c 'lua print(vim.fn.gettext("E492: Not an editor command"))' \
  -c 'qa!'
# 输出：E492: 不是编辑器的命令
```

### 3.3 部署配置

```bash
cd ~/path/to/kickstart.neovim
mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
ln -sfn "$PWD/nvim" ~/.config/nvim
```

想用复制而不是软链接：

```bash
mkdir -p ~/.config/nvim
rsync -a nvim/ ~/.config/nvim/
```

### 3.4 安装插件

```bash
nvim --headless "+Lazy! sync" "+qa"
```

首次会下载 30 多个插件，取决于网络，通常 2–10 分钟。

### 3.5 安装 Treesitter 解析器（可选）

```bash
nvim --headless "+luafile scripts/treesitter-install.lua" "+qa!"
```

不装也能用，只是没有对应语言的语法高亮。

### 3.6 验证

```bash
nvim --headless "+lua print(vim.g.l10n_locale)" "+qa"
# 期望：zh_CN.utf8

nvim
# 进入后执行：
:checkhealth
```

---

## 4. 安装后检查清单

- [ ] `nvim --version` 显示 v0.12.6，且 `LuaJIT` 存在
- [ ] 启动页按钮为中文（查找文件 / 新建文件 / …）
- [ ] `:lua print(vim.g.l10n_locale)` 输出 `zh_CN.utf8`
- [ ] 输入错误命令（如 `:nosuchcmd`）提示为中文
- [ ] `<Space>ff` 能打开文件列表
- [ ] `<Space>uM` 能在中/英界面间切换（消息、菜单、启动页、状态栏全部生效）
- [ ] `:checkhealth lazyvim` 无红色错误

---

## 5. 更新

### 更新插件

```bash
nvim
:Lazy update
```

或在命令行：

```bash
nvim --headless "+Lazy! update" "+qa"
```

更新后 `nvim/lazy-lock.json` 会变化，记得提交：

```bash
git -C ~/.config/nvim add lazy-lock.json
git -C ~/.config/nvim commit -m "chore: 更新插件锁文件"
git -C ~/.config/nvim push
```

### 更新 Neovim

```bash
NVIM_VERSION=v0.12.6 bash scripts/install.sh --force
```

同时会重新下载并编译对应版本的中文语言包。

---

## 6. 卸载

```bash
bash scripts/uninstall.sh
```

- 只移除脚本创建的软链接
- 不会删除真实配置目录与备份

彻底清理（会二次确认）：

```bash
bash scripts/uninstall.sh --purge
```

手动恢复备份：

```bash
ls -d ~/.config/nvim.bak.*
mv ~/.config/nvim.bak.20261027-210000 ~/.config/nvim
```
