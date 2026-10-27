# 汉化说明

本仓库的汉化分四层，全部在配置目录内完成，不改动 LazyVim 与插件源码。

---

## 1. 总览

| 层级 | 内容 | 文件 |
|---|---|---|
| ① 内置消息 | 报错、提示、`v:errmsg` 等 | `lua/config/options.lua` + `nvim.mo` |
| ② which-key | `<Space>` 后的分组名 | `lua/config/l10n.lua` |
| ③ 启动页 | dashboard 按钮文字 | `lua/plugins/l10n.lua` |
| ④ 状态栏 | NORMAL / INSERT 等模式名 | `lua/plugins/l10n.lua` |

切换键：`<leader>uM`（`<Space>uM`，M = Menu）在中文 / English 之间切换。
四层会同时生效，**不需要重启**：内置消息（运行时 `:language`）、which-key 分组、
dashboard 按钮、lualine 模式名。

选择会写入 `stdpath("state")/kickstart-l10n.json`（通常是
`~/.local/state/nvim/kickstart-l10n.json`），重开 Neovim 后保持；删掉该文件即恢复默认中文。

> `<leader>uC` 是 LazyVim 的颜色方案选择器，所以这里用 `uM`，避免冲突。

---

## 2. 内置消息（gettext）

### 2.1 为什么需要自己编译

Neovim 源码里有 `src/nvim/po/zh_CN.UTF-8.po`，但官方 release tarball 和
Ubuntu 的 `.deb` 都没有把 `.mo` 一起打包。所以运行：

```vim
:language zh_CN.utf8
```

会得到 `E197: Cannot set language to "zh_CN"`（或直接无效）。

### 2.2 安装位置

```text
~/.local/opt/nvim-0.12.6/share/locale/zh_CN/LC_MESSAGES/nvim.mo
~/.local/opt/nvim-0.12.6/share/locale/zh_CN.utf8/LC_MESSAGES/nvim.mo
```

两份是为了兼容不同 glibc 的 locale 命名。

### 2.3 配置里的写法

`lua/config/options.lua` 只做一件事：让 `lua/config/l10n.lua` 按当前选择设置语言。

```lua
require("config.l10n").apply_locale({ notify = true })
```

`l10n.lua` 内部按顺序尝试 locale，成功即停止：

```lua
M.locales = {
  zh = { "zh_CN.utf8", "zh_CN.UTF-8", "zh_CN" },
  en = { "en_US.utf8", "en_US.UTF-8", "C.UTF-8", "C" }, -- C 一定存在
}
```

- 逐个尝试，避免某个名称不被系统支持（否则报 `E197`）
- 成功时记录到 `vim.g.l10n_locale`，便于 `:lua print(vim.g.l10n_locale)` 排查
- 失败时只提示，不阻止启动
- 切换语言时再次调用 `apply_locale()` 即可立即生效，无需重启

### 2.4 重新生成

Neovim 升级后，翻译会变化，需要重新编译。安装脚本会自动解析最新版本并重装语言包：

```bash
bash scripts/install.sh --force
```

若固定到某个版本（下面的版本号需与已安装的 Neovim 一致）：

```bash
NVIM_VERSION=v0.12.6 bash scripts/install.sh --force
```

或手动（把 `v0.12.6` 换成你实际安装的版本）：

```bash
curl -fLO https://raw.githubusercontent.com/neovim/neovim/v0.12.6/src/nvim/po/zh_CN.UTF-8.po
python3 scripts/po2mo.py zh_CN.UTF-8.po /tmp/nvim.mo
install -Dm644 /tmp/nvim.mo ~/.local/opt/nvim-0.12.6/share/locale/zh_CN.utf8/LC_MESSAGES/nvim.mo
```

---

## 3. which-key 菜单

`lua/config/l10n.lua` 维护一张分组表：

```lua
M.groups = {
  { "<leader>f", zh = "文件/查找", en = "file/find" },
  { "<leader>b", zh = "缓冲区", en = "buffer", expand = "buf" },
  { "<leader>w", zh = "窗口", en = "windows", expand = "win", proxy = "<c-w>" },
  -- ...
}
```

启动时等 which-key 完成 setup，再调用 `wk.add()` 覆盖分组名：

```lua
function M.apply()
  local ok, conf = pcall(require, "which-key.config")
  if not ok or not conf.loaded then
    return false
  end

  local wk = require("which-key")
  wk.add(specs)
  return true
end
```

> 为什么不能直接写在 `opts.spec` 里？
> LazyVim 的 which-key 是异步 setup 的，直接追加 spec 可能被上游默认值覆盖。
> 这里用「等 loaded 后再 add」的方式，保证中文名最终生效。

### 新增分组翻译

1. 打开 `nvim/lua/config/l10n.lua`
2. 在 `M.groups` 里加一行：

```lua
{ "<leader>z", zh = "我的分组", en = "my group" },
```

3. `<leader>uM` 切换语言，或手动执行 `:lua require("config.l10n").apply()`

`expand` / `proxy` 只对 LazyVim 原生有特殊行为的分组（buffer、windows）需要，
普通分组只写 `zh` / `en` 即可。

---

## 4. 启动页（dashboard）

词典在 `lua/config/l10n.lua` 的 `M.dashboard.zh`，`lua/plugins/l10n.lua` 在 Snacks
初始化时调用 `l10n.dashboard_desc()` 应用：

```lua
M.dashboard = {
  zh = {
    ["Find File"] = "查找文件",
    ["New File"] = "新建文件",
    ["Find Text"] = "查找文本",
    ["Recent Files"] = "最近文件",
    ["Config"] = "打开配置",
    ["Restore Session"] = "恢复会话",
    ["Lazy Extras"] = "Lazy 扩展",
    ["Lazy"] = "插件管理",
    ["Quit"] = "退出",
  },
}
```

切换语言时 `M.apply_dashboard()` 会反向映射回英文；如果当时正停在启动页，
会立即重绘。想加别的按钮或改文案，直接改这张表。

---

## 5. 状态栏模式名

lualine 的 `mode` 组件返回 `NORMAL` / `INSERT` 等字符串，映射表在
`lua/config/l10n.lua`（`M.modes_zh`），组件每次都调用 `l10n.mode()`：

```lua
opts.sections.lualine_a = {
  { "mode", fmt = function(str) return l10n.mode(str) end },
}
```

因此切换语言后只需 `require("lualine").refresh()`，不需要重新 setup。
效果：左下角显示「普通 / 插入 / 可视 / 命令」，英文模式下回到 `NORMAL` 等。

---

## 6. 哪些内容没有汉化

以下属于上游插件内部字符串，**不建议**在配置层硬改：

| 内容 | 原因 |
|---|---|
| `:Lazy` 插件面板 | lazy.nvim 未提供 i18n 接口 |
| `:checkhealth` 输出 | 插件各自实现 |
| `:help` 文档 | 官方只有英文 |
| LSP 错误、诊断信息 | 来自语言服务器 |
| 各插件自己的 `vim.notify` | 字符串写死在插件里 |
| 补全菜单中的来源名 | 插件内部 |

如果必须在某处显示中文，可以在自己的键位 / 命令里包一层：

```lua
vim.keymap.set("n", "<leader>xx", function()
  vim.notify("这是我的中文提示", vim.log.levels.INFO)
end, { desc = "示例" })
```

---

## 7. 关闭汉化

- 随时切换中/英：`<leader>uM`（消息、菜单、启动页、状态栏一起切换，立即生效）

  选择会持久化；想恢复默认中文，删除状态文件即可：

  ```bash
  rm -f ~/.local/state/nvim/kickstart-l10n.json
  ```

- 想让新机器默认就是英文：把 `nvim/lua/config/l10n.lua` 里的默认值改掉

  ```lua
  -- M.enabled = load_enabled()
  -- if M.enabled == nil then M.enabled = true end
  if M.enabled == nil then M.enabled = false end
  ```

  或者安装后按一次 `<leader>uM`，状态会自动保存。

---

## 8. 局限与预期

- 内置消息翻译**不完整**：上游 `.po` 只覆盖一部分字符串，未翻译的仍显示英文
- 中文报错中的路径、变量名保持原样，这是 gettext 的正常行为
- 终端字体必须支持中文；若出现方块，检查终端字体与 locale，见
  [troubleshooting.md](troubleshooting.md)
