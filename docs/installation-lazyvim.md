# LazyVim 配置说明

本文说明 LazyVim 的结构、配置加载顺序，以及本仓库在 starter 基础上做了哪些改动。

---

## 1. LazyVim 与 lazy.nvim 的关系

| 名称 | 角色 |
|---|---|
| **lazy.nvim** | 插件管理器：安装、更新、懒加载、锁版本 |
| **LazyVim** | 一套基于 lazy.nvim 的发行版：预配置好的插件、键位、LSP、补全、UI |
| **LazyVim starter** | 官方最小配置模板，本仓库的 `nvim/` 以它为骨架 |

三者关系：

```text
Neovim
└── lazy.nvim（插件管理器）
    ├── LazyVim（发行版）
    │   └── lazyvim.plugins.*（默认插件与键位）
    └── lua/plugins/*.lua（你的覆盖与新增）
```

---

## 2. 配置加载顺序

```text
init.lua
├── lua/config/options.lua      # LazyVim 在 lazy.nvim 之前自动加载
├── lua/config/lazy.lua         # 引导 lazy.nvim
│   ├── lazyvim.plugins         # LazyVim 默认插件
│   └── lua/plugins/*           # 本仓库插件与覆盖
└── lua/config/l10n.lua         # which-key 就绪后应用中文菜单
```

LazyVim 还会自动加载：

- `lua/config/keymaps.lua`
- `lua/config/autocmds.lua`

因此不需要在 `init.lua` 里手动 `require` 这两个文件。

---

## 3. 目录职责

```text
nvim/
├── init.lua                 # 入口
├── lazy-lock.json           # 插件版本锁（要提交）
├── lazyvim.json             # 启用的 Extras（要提交）
├── lua/config/
│   ├── options.lua          # 中文消息、编码、折行
│   ├── keymaps.lua          # 自定义键位
│   ├── autocmds.lua         # 复制高亮
│   ├── lazy.lua             # lazy.nvim 设置
│   └── l10n.lua             # which-key 汉化与切换
└── lua/plugins/
    └── l10n.lua             # dashboard / lualine 汉化
```

新增插件时，在 `lua/plugins/` 下新建文件并返回 lazy.nvim 规范即可。

---

## 4. 插件管理

### 打开面板

```vim
:Lazy
```

常用操作：

| 键 | 功能 |
|---|---|
| `I` | 安装缺失插件 |
| `U` | 更新全部 |
| `S` | 同步（安装 + 清理 + 更新锁文件） |
| `X` | 清理未使用插件 |
| `L` | 查看日志 |
| `C` | 查看配置 |
| `H` | 查看提交历史 |

### 命令行

```bash
nvim --headless "+Lazy! sync" "+qa"      # 同步
nvim --headless "+Lazy! update" "+qa"    # 更新
nvim --headless "+Lazy! clean" "+qa"     # 清理
```

### 锁文件

`lazy-lock.json` 记录每个插件的 commit。**建议提交到仓库**，这样换机器能复现同一套版本。

更新插件后：

```bash
git add nvim/lazy-lock.json
git commit -m "chore: 更新插件"
git push
```

---

## 5. LazyVim Extras

LazyVim 把语言支持、工具集成做成可选项（Extras）：

```vim
:LazyExtras
```

例如：

- `lang.python`：Python LSP / 格式化 / lint
- `lang.typescript`：TS/JS 支持
- `dap.core`：调试器
- `editor.mini-surround`：更顺手的环绕操作
- `ui.mini-animate`：动画

启用后会写入 `lazyvim.json` 并安装对应插件。`lazyvim.json` 也要提交。

> 建议按需启用。每启用一个语言 Extra，首次启动都会下载 LSP / 格式化工具，注意网络。

---

## 6. 本仓库相对 starter 的改动

| 文件 | 改动 |
|---|---|
| `lua/config/options.lua` | 中文消息、编码兼容、Markdown 折行 |
| `lua/config/l10n.lua` | which-key 分组、dashboard/lualine 词典、`<leader>uM` 切换与持久化 |
| `lua/plugins/l10n.lua` | dashboard 按钮、lualine 模式名汉化 |
| `lua/config/lazy.lua` | 关闭 luarocks（无插件依赖）、中文注释 |
| `lua/config/keymaps.lua` | `<Esc>` 清除搜索高亮 |
| `lua/config/autocmds.lua` | 复制高亮（使用 `vim.hl.on_yank`） |

其余保持 LazyVim starter 默认，便于跟进上游更新。

---

## 7. 健康检查

```vim
:checkhealth
```

重点看：

- `lazyvim`：Neovim 版本、git、rg、fd、lazygit、tree-sitter
- `lazy`：插件管理器与 luarocks
- `snacks`：选择器、图片、终端
- `clipboard`：系统剪贴板

部分 `snacks` 的报错是因为在 headless 下检查，实际 TUI 中正常；以实际使用为准。

---

## 8. 跟进上游

```bash
cd ~/.config/nvim
# LazyVim 本身由 lazy.nvim 管理，:Lazy update 会一起更新
```

如果上游改了默认键位，本仓库的 which-key 中文名可能需要同步调整：
`lua/config/l10n.lua` 里的 `groups` 表是手工维护的，未命中的分组会保持英文，不会报错。
