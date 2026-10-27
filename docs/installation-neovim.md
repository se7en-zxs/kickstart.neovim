# 安装 Neovim 与中文语言包

本文只讲 Neovim 本体：为什么用官方 tarball、中文消息是怎么生效的、以及版本/路径管理。

---

## 1. 为什么用官方 tarball

Ubuntu 仓库的 Neovim 往往落后，而且部分发行版包**没有编译翻译文件**。
本项目默认：

- 官方 release tarball（v0.12.6）
- 自带 LuaJIT
- 安装到 `~/.local/opt`，不需要 sudo
- 中文语言包自行编译，可控、可复现

LazyVim 要求 **Neovim ≥ 0.11.2（LuaJIT 构建）**，v0.12.6 满足要求。

目录约定：

```text
~/.local/opt/nvim-0.12.6/       # 实际安装目录
~/.local/opt/nvim -> nvim-0.12.6
~/.local/bin/nvim -> ~/.local/opt/nvim/bin/nvim
```

这样切换版本只需改两个软链接，旧版本仍保留。

---

## 2. 下载与安装

```bash
NVIM_VERSION=v0.12.6
ARCH=$(uname -m)   # x86_64 或 arm64

mkdir -p ~/.local/opt ~/.local/bin
cd /tmp
curl -fLO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${ARCH}.tar.gz"
tar xzf "nvim-linux-${ARCH}.tar.gz" -C ~/.local/opt
mv ~/.local/opt/nvim-linux-${ARCH} ~/.local/opt/nvim-${NVIM_VERSION#v}

ln -sfn ~/.local/opt/nvim-${NVIM_VERSION#v} ~/.local/opt/nvim
ln -sfn ~/.local/opt/nvim/bin/nvim ~/.local/bin/nvim
```

验证：

```bash
nvim --version
# NVIM v0.12.6
# Build type: Release
# LuaJIT 2.1.x
```

> **重要**：`nvim --version` 中的 `LuaJIT` 必须存在。如果显示 `Lua 5.1` 而没有 JIT，
> LazyVim 的部分功能会报错。

### 网络下载失败

- 设置代理：`https_proxy=http://127.0.0.1:7890`
- 或使用 `NVIM_TARBALL_URL=file:///path/to/nvim.tar.gz`
- 或从镜像站手动下载后放到 `~/.local/opt`

---

## 3. 中文语言包（重点）

### 3.1 原理

Neovim 的报错与提示通过 gettext 翻译：

1. 源码里的翻译文件是 `src/nvim/po/zh_CN.UTF-8.po`
2. 运行时读取 `<prefix>/share/locale/<locale>/LC_MESSAGES/nvim.mo`
3. `:language zh_CN.utf8` 切换 gettext 语言

官方 tarball 与 Ubuntu 的 .deb **都不带 `nvim.mo`**，所以需要自己编译。
本项目用 `scripts/po2mo.py`（纯 Python，无需 msgfmt）完成转换。

### 3.2 编译与安装

```bash
cd ~/path/to/kickstart.neovim

curl -fLO https://raw.githubusercontent.com/neovim/neovim/v0.12.6/src/nvim/po/zh_CN.UTF-8.po
python3 scripts/po2mo.py zh_CN.UTF-8.po /tmp/nvim.mo

for loc in zh_CN zh_CN.utf8; do
  install -Dm644 /tmp/nvim.mo \
    ~/.local/opt/nvim-0.12.6/share/locale/$loc/LC_MESSAGES/nvim.mo
done
```

放两份是因为不同发行版的 locale 名称可能是 `zh_CN` 或 `zh_CN.utf8`。

### 3.3 验证

```bash
LANGUAGE=zh_CN.utf8 nvim --headless -u NONE \
  -c 'language zh_CN.utf8' \
  -c 'lua print(vim.fn.gettext("E492: Not an editor command"))' \
  -c 'qa!'
```

看到 `E492: 不是编辑器的命令` 即成功。

在配置中（`nvim/lua/config/options.lua`）会按顺序尝试：

```lua
zh_CN.utf8 → zh_CN.UTF-8 → zh_CN
```

失败时用 `vim.notify_once` 提示，并回退英文，不会阻止启动。

### 3.4 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| `E197: Cannot set language to "zh_CN"` | locale 名不对 / 系统未生成 | 用 `locale -a \| grep zh` 查可用名称，优先 `.utf8` |
| 报错仍是英文 | `nvim.mo` 不在 Neovim 的 `share/locale` 下 | 确认 `.mo` 路径与 `nvim` 实际安装目录一致 |
| 只有部分提示是中文 | 上游翻译不完整 | 正常现象，见 [installation-chinese.md](installation-chinese.md#局限) |

系统若没有中文 locale，可以生成（需要 sudo）：

```bash
sudo locale-gen zh_CN.UTF-8
sudo update-locale
```

但通常 Ubuntu 桌面版默认已带 `zh_CN.utf8`。

---

## 4. 想用系统自带的 Neovim？

```bash
bash scripts/install.sh --no-nvim
```

此时：

- 不下载 Neovim，也不安装中文语言包
- 配置仍然会部署并安装插件
- 若系统版版本 < 0.11.2，LazyVim 会拒绝启动

所以除非你的系统版足够新且自带 `nvim.mo`，否则不推荐。

---

## 5. 多版本共存

```bash
# 安装 0.11.6
NVIM_VERSION=v0.11.6 bash scripts/install.sh

# 切回 0.12.6
ln -sfn ~/.local/opt/nvim-0.12.6 ~/.local/opt/nvim
ln -sfn ~/.local/opt/nvim/bin/nvim ~/.local/bin/nvim
```

注意：不同版本的中文语言包分别在各自目录下，互不影响。

---

## 6. 卸载

```bash
# 只删除软链接（保留版本目录）
rm -f ~/.local/bin/nvim ~/.local/opt/nvim

# 彻底删除所有版本
rm -rf ~/.local/opt/nvim-*
```
