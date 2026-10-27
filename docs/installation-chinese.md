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

切换键：`<leader>uC`（`<Space>uC`）在中文 / English 菜单之间切换。
**内置消息的语言切换需要重启 Neovim**，which-key 与 dashboard 则会立即更新。

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

`lua/config/options.lua`：

```lua
local locale_ok = false
for _, locale in ipairs({ "zh_CN.utf8", "zh_CN.UTF-8", "zh_CN" }) do
  if pcall(vim.cmd, "language " .. locale) then
    vim.g.l10n_locale = locale
    locale_ok = true
    break
  end
end
```

- 逐个尝试，避免某个名称不被系统支持
- 成功时记录到 `vim.g.l10n_locale`，便于 `:lua print(vim.g.l10n_locale)` 排查
- 失败时只提示，不阻止启动

### 2.4 重新生成

Neovim 升级后，翻译会变化，需要重新编译：

```bash
NVIM_VERSION=v0.12.6 bash scripts/install.sh --force
```

或手动：

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

3. 重启 Neovim，或执行 `:lua require("config.l10n").apply()`

`expand` / `proxy` 只对 LazyVim 原生有特殊行为的分组（buffer、windows）需要，
普通分组只写 `zh` / `en` 即可。

---

## 4. 启动页（dashboard）

`lua/plugins/l10n.lua` 在 Snacks 初始化前修改 `preset.keys`：

```lua
local zh = {
  ["Find File"] = "查找文件",
  ["New File"] = "新建文件",
  ["Find Text"] = "查找文本",
  ["Recent Files"] = "最近文件",
  ["Config"] = "打开配置",
  ["Restore Session"] = "恢复会话",
  ["Lazy Extras"] = "Lazy 扩展",
  ["Lazy"] = "插件管理",
  ["Quit"] = "退出",
}
```

想加别的按钮或改文案，直接改这张表。

---

## 5. 状态栏模式名

lualine 的 `mode` 组件返回 `NORMAL` / `INSERT` 等字符串，这里做映射：

```lua
local mode_zh = {
  NORMAL = "普通",
  INSERT = "插入",
  VISUAL = "可视",
  -- ...
}
```

效果：左下角显示「普通 / 插入 / 可视 / 命令」。

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

- 临时切回英文菜单：`<leader>uC`
- 永久关闭 which-key 汉化：

  ```lua
  -- nvim/lua/config/l10n.lua
  M.enabled = false
  ```

- 内置消息回到英文：删除 `options.lua` 里的 `language` 循环，或在启动后执行
  `:language C`

---

## 8. 局限与预期

- 内置消息翻译**不完整**：上游 `.po` 只覆盖一部分字符串，未翻译的仍显示英文
- 中文报错中的路径、变量名保持原样，这是 gettext 的正常行为
- 终端字体必须支持中文；若出现方块，检查终端字体与 locale，见
  [troubleshooting.md](troubleshooting.md)
