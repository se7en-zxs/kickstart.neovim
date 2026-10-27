# kickstart.neovim

**Neovim + LazyVim 中文开箱配置** —— 从零安装 Neovim、铺装 LazyVim、完成界面汉化，并把整套配置与安装过程沉淀成可复用的仓库。

> 定位：个人 / 团队的 Neovim 起步基线。**一条命令装好**，之后所有自定义都直接提交回本仓库。

---

## 快速开始

```bash
git clone https://github.com/se7en-zxs/kickstart.neovim.git
cd kickstart.neovim
bash scripts/install.sh
```

脚本会依次完成：

1. 下载官方 **Neovim v0.12.6** 到 `~/.local/opt`，软链到 `~/.local/bin/nvim`（无需 sudo）
2. 把 Neovim 官方中文 `.po` 编译成 `nvim.mo`，让报错与提示变成中文
3. 安装 `ripgrep` / `fd` / `fzf` / `lazygit` / `tree-sitter`（用户目录，无需 sudo）
4. 把本仓库的 `nvim/` **软链接**到 `~/.config/nvim`
5. 安装 LazyVim 插件与 Treesitter 解析器

装完直接运行：

```bash
nvim
```

首次启动如果还有插件在补装，等 `:Lazy` 窗口完成即可。

### 常用参数

| 参数 | 作用 |
|---|---|
| `--copy` | 复制配置而不是软链接（之后用 `scripts/sync-back.sh` 同步回仓库） |
| `--no-nvim` | 使用系统已有的 `nvim`，不安装官方版本 |
| `--no-tools` | 不安装 rg / fd / fzf / lazygit |
| `--no-treesitter` | 不预装 Treesitter 解析器 |
| `--force` | 强制重新下载 Neovim 与工具 |
| `--version v0.11.6` | 指定 Neovim 版本 |

完整说明见 [docs/installation.md](docs/installation.md)。

---

## 这套配置包含什么

### 基础

- **Neovim 0.12.6**（官方 release tarball，LuaJIT 构建）
- **LazyVim**（stable 分支）+ lazy.nvim 插件管理
- 文件编码兼容：UTF-8 / GB18030 / GBK / Big5
- Markdown、文本、gitcommit 自动折行

### 汉化

| 范围 | 实现 |
|---|---|
| Neovim 内置消息（报错、提示） | 官方 `zh_CN.UTF-8.po` → `nvim.mo`，`language zh_CN.utf8` |
| which-key 分组菜单 | `lua/config/l10n.lua` 覆盖 LazyVim 默认分组名 |
| 启动页 dashboard 按钮 | `lua/config/l10n.lua` 提供词典，`lua/plugins/l10n.lua` 应用 |
| 状态栏模式名 | lualine 显示「普通 / 插入 / 可视…」 |
| 中英切换 | `<leader>uM`（`<Space>uM`）一键切换消息、菜单、启动页与状态栏，重启后保持 |

> 第三方插件内部的提示（例如 `:Lazy` 面板、`:help` 文档）仍是英文，这是上游限制。详见 [docs/installation-chinese.md](docs/installation-chinese.md)。

> 语言选择保存在 `~/.local/state/nvim/kickstart-l10n.json`；删掉该文件即恢复默认中文。

### 已装工具

| 工具 | 用途 |
|---|---|
| `rg` (ripgrep) | 全文搜索 `<leader>fg` |
| `fd` | 文件查找 `<leader>ff` |
| `fzf` | 可选选择器后端 |
| `lazygit` | `<leader>gg` 图形化 Git |
| `tree-sitter` | 编译 Treesitter 解析器 |

---

## 目录结构

```text
kickstart.neovim/
├── README.md
├── docs/
│   ├── installation.md              # 安装总览（一键 + 手动）
│   ├── installation-neovim.md       # Neovim 本体与中文语言包
│   ├── installation-lazyvim.md      # LazyVim 结构、插件管理、Extras
│   ├── installation-chinese.md      # 汉化原理与扩展词典
│   ├── customization.md             # 后续自定义与同步到 GitHub
│   └── troubleshooting.md           # 字体、乱码、代理、Treesitter 等
├── scripts/
│   ├── install.sh                   # 一键安装
│   ├── po2mo.py                     # 纯 Python 的 .po → .mo 编译器
│   ├── treesitter-install.lua       # 预装解析器
│   ├── sync-back.sh                 # --copy 模式同步回仓库
│   └── uninstall.sh                 # 保守卸载
└── nvim/                            # 真正的 Neovim 配置目录
    ├── init.lua
    ├── lazy-lock.json
    ├── lazyvim.json
    └── lua/
        ├── config/
        │   ├── lazy.lua             # lazy.nvim 引导
        │   ├── options.lua          # 中文消息、编码等
        │   ├── keymaps.lua          # 自定义键位
        │   ├── autocmds.lua         # 自动命令
        │   └── l10n.lua             # which-key 汉化 + 中英切换
        └── plugins/
            └── l10n.lua             # dashboard / lualine 汉化
```

安装完成后：

- `~/.config/nvim` → 仓库的 `nvim/`（软链接）
- 插件数据在 `~/.local/share/nvim`
- 因此**在 `~/.config/nvim` 里的任何改动，就是仓库里的改动**，直接 commit / push 即可同步。

---

## 后续自定义与同步

默认使用软链接模式，流程非常简单：

```bash
cd ~/.config/nvim          # 实际进入仓库的 nvim/ 目录
nvim lua/plugins/my.lua    # 新增插件 / 修改配置
git add -A
git commit -m "feat: 添加 xxx 插件"
git push
```

如果安装时用了 `--copy`：

```bash
bash scripts/sync-back.sh
git add -A && git commit -m "chore: 同步配置" && git push
```

换一台机器时，重新 clone 本仓库并执行 `scripts/install.sh` 即可复现。

详见 [docs/customization.md](docs/customization.md)。

---

## 常用键位

| 键位 | 功能 |
|---|---|
| `<Space>ff` | 查找文件 |
| `<Space>fg` | 全文搜索 |
| `<Space>e` | 文件浏览器 |
| `<Space>gg` | lazygit |
| `<Space>qq` | 退出 |
| `<Space>uM` | 切换界面语言（中/英，立即生效并记住选择） |
| `<Space>uC` | 切换颜色方案（LazyVim 默认键位） |
| `<Space>?` | 查看当前缓冲区键位 |
| `:Lazy` | 插件管理 |
| `:checkhealth` | 环境检查 |

LazyVim 完整键位：<https://lazyvim.github.io/keymaps>

---

## 环境与版本

本仓库在以下环境实测通过：

- Ubuntu 26.04 LTS（x86_64）
- Neovim v0.12.6（官方 release）
- LazyVim stable
- 终端：xterm-256color 兼容终端

其他 Linux 发行版、macOS 可参考脚本手动调整；Windows 建议直接用 WSL。

---

## 卸载

```bash
bash scripts/uninstall.sh          # 移除软链（保留真实配置与备份）
bash scripts/uninstall.sh --purge  # 额外删除 Neovim 与插件数据（会二次确认）
```

备份目录形如 `~/.config/nvim.bak.20261027-210000`，不会被自动删除。

---

## 参考与致谢

- [Neovim](https://neovim.io/)
- [LazyVim](https://lazyvim.github.io/) / [LazyVim starter](https://github.com/LazyVim/starter)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [which-key.nvim](https://github.com/folke/which-key.nvim)
- [Snacks.nvim](https://github.com/folke/snacks.nvim)

`nvim/LICENSE` 为 LazyVim starter 的 Apache-2.0 许可证，保留以符合其授权要求。
