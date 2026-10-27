# 后续自定义与同步

目标：**在 `~/.config/nvim` 里改的东西，就是仓库里的东西**，不需要“导出/导入”。

---

## 1. 两种部署模式

### 软链接模式（默认，推荐）

```bash
bash scripts/install.sh          # 等价于 bash scripts/install.sh --link
```

```text
~/.config/nvim -> /path/to/kickstart.neovim/nvim
```

- 改动即时写入仓库工作区
- 插件更新写入的 `lazy-lock.json` 也在仓库里
- 直接 `git diff` 就能看到所有变化

### 复制模式

```bash
bash scripts/install.sh --copy
```

```text
~/.config/nvim/           # 独立副本
/path/to/kickstart.neovim/nvim/   # 仓库
```

改完需要同步回仓库：

```bash
bash scripts/sync-back.sh
```

`sync-back.sh` 会执行 `rsync -a --delete` 并显示 `git status`。

> 除非你有特殊理由（例如配置目录必须独立、要挂载到容器），建议用软链接。

---

## 2. 日常流程

```bash
cd ~/.config/nvim      # 软链接模式下就是仓库的 nvim/
git status
git add -A
git commit -m "feat: 添加 xxx"
git push
```

换一台机器：

```bash
git clone https://github.com/se7en-zxs/kickstart.neovim.git
cd kickstart.neovim
bash scripts/install.sh
```

已安装的机器拉取更新：

```bash
git -C ~/.config/nvim pull --rebase
nvim --headless "+Lazy! sync" "+qa"
```

---

## 3. 新增插件

在 `nvim/lua/plugins/` 下新建文件，例如 `nvim/lua/plugins/comment.lua`：

```lua
return {
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
```

重启 Neovim，`lazy.nvim` 会自动安装。然后：

```bash
git add nvim/lua/plugins/comment.lua nvim/lazy-lock.json
git commit -m "feat: 添加 Comment.nvim"
```

### 覆盖 LazyVim 已有插件

```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    enabled = false,        -- 或覆盖 opts
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = { enabled = false },
    },
  },
}
```

LazyVim 的插件默认配置在
`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/`，可以直接阅读。

---

## 4. 新增键位

编辑 `nvim/lua/config/keymaps.lua`：

```lua
vim.keymap.set("n", "<leader>mp", function()
  vim.notify("Hello")
end, { desc = "示例命令" })
```

`desc` 会显示在 which-key 中。若想给分组加中文名，见
[installation-chinese.md](installation-chinese.md#3-which-key-菜单)。

---

## 5. 启用 LazyVim Extras

```vim
:LazyExtras
```

选择后会自动写入 `nvim/lazyvim.json` 并安装插件。

提交：

```bash
git add nvim/lazyvim.json nvim/lazy-lock.json
git commit -m "feat: 启用 Python / TypeScript extras"
```

> 每个语言 Extra 会引入 LSP、格式化、lint 工具，首次安装时间较长。

---

## 6. 哪些文件要提交

| 文件 | 是否提交 | 说明 |
|---|---|---|
| `nvim/init.lua`、`lua/**` | ✅ | 配置主体 |
| `nvim/lazy-lock.json` | ✅ | 固定插件版本，保证可复现 |
| `nvim/lazyvim.json` | ✅ | Extras 列表 |
| `nvim/.neoconf.json` | ✅ | Lua LSP 配置 |
| `~/.local/share/nvim/**` | ❌ | 插件数据，不入库 |
| `~/.local/state/nvim/**` | ❌ | 状态数据 |
| 备份目录 `*.bak.*` | ❌ | 不提交 |

`.gitignore` 已处理 Python 缓存、日志、临时文件。

---

## 7. 回滚

### 回滚配置

```bash
git -C ~/.config/nvim log --oneline
git -C ~/.config/nvim revert <commit>
```

### 回滚插件

```bash
git -C ~/.config/nvim checkout HEAD~1 -- nvim/lazy-lock.json
nvim --headless "+Lazy! restore" "+qa"
```

### 恢复安装前的配置

```bash
ls -d ~/.config/nvim.bak.*
rm ~/.config/nvim            # 如果是软链接
mv ~/.config/nvim.bak.20261027-210000 ~/.config/nvim
```

---

## 8. 多机同步建议

- 所有机器统一用软链接模式
- 每次改完先 `git pull --rebase` 再改，减少冲突
- `lazy-lock.json` 冲突时：选一台机器上的版本，另一台执行 `:Lazy restore` 对齐
- 机器特有的路径/密钥不要写进仓库（例如公司代理地址）

---

## 9. 提交信息参考

```text
feat: 添加 xxx 插件
fix: 修复中文菜单在 which-key 中不生效
chore: 更新插件锁文件
docs: 补充代理配置说明
```
