-- 界面汉化：which-key 分组名 + 中/英切换
--
-- 说明：
--   * Neovim 内置消息的语言在 lua/config/options.lua 中设置（gettext，切换需重启）。
--   * 本模块只处理 which-key 的分组标题，不影响 LazyVim 的功能与键位。
--   * 未收录的插件/键位描述保持原样，避免误译。
local M = {}

M.enabled = true

-- lhs = 键位前缀，zh/en = 两种语言下的分组名
-- mode 默认 {"n", "x"}；g/[/]/z 等仅在普通模式生效
M.groups = {
  { "<leader><tab>", zh = "标签页", en = "tabs" },
  { "<leader>b", zh = "缓冲区", en = "buffer", expand = "buf" },
  { "<leader>c", zh = "代码", en = "code" },
  { "<leader>cx", zh = "提取", en = "extract" },
  { "<leader>d", zh = "调试", en = "debug" },
  { "<leader>dp", zh = "性能分析", en = "profiler" },
  { "<leader>f", zh = "文件/查找", en = "file/find" },
  { "<leader>g", zh = "Git", en = "git" },
  { "<leader>gh", zh = "代码块（hunk）", en = "hunks" },
  { "<leader>o", zh = "任务", en = "overseer" },
  { "<leader>q", zh = "退出/会话", en = "quit/session" },
  { "<leader>s", zh = "搜索", en = "search" },
  { "<leader>sn", zh = "消息", en = "noice" },
  { "<leader>t", zh = "测试", en = "test" },
  { "<leader>u", zh = "界面", en = "ui" },
  { "<leader>w", zh = "窗口", en = "windows", expand = "win", proxy = "<c-w>" },
  { "<leader>x", zh = "诊断/快速修复", en = "diagnostics/quickfix" },
  { "g", zh = "跳转", en = "goto", mode = { "n" } },
  { "gs", zh = "包围", en = "surround", mode = { "n" } },
  { "z", zh = "折叠", en = "fold", mode = { "n" } },
  { "[", zh = "上一个", en = "prev", mode = { "n" } },
  { "]", zh = "下一个", en = "next", mode = { "n" } },
}

-- 非分组的键位描述覆盖
M.descriptions = {
  { "<leader>?", zh = "当前缓冲区键位", en = "Buffer Keymaps (which-key)", mode = { "n", "x" } },
  { "<leader>uC", zh = "切换界面语言（中/英）", en = "Toggle UI language (zh/en)", mode = { "n" } },
}

local function expand(name)
  return function()
    local extras = require("which-key.extras")
    return name == "buf" and extras.expand.buf() or extras.expand.win()
  end
end

---把当前语言应用到 which-key
---@return boolean 是否成功（which-key 尚未加载完成时返回 false）
function M.apply()
  local ok, conf = pcall(require, "which-key.config")
  if not ok or not conf.loaded then
    return false
  end
  local wk = require("which-key")

  local specs = {}
  for _, g in ipairs(M.groups) do
    specs[#specs + 1] = {
      g[1],
      group = M.enabled and g.zh or g.en,
      mode = g.mode or { "n", "x" },
      expand = g.expand and expand(g.expand) or nil,
      proxy = g.proxy,
    }
  end
  for _, d in ipairs(M.descriptions) do
    specs[#specs + 1] = {
      d[1],
      desc = M.enabled and d.zh or d.en,
      mode = d.mode or { "n", "x" },
    }
  end

  wk.add(specs)
  vim.g.l10n_ui = M.enabled
  return true
end

---在中/英文菜单之间切换
function M.toggle()
  M.enabled = not M.enabled
  if not M.apply() then
    M.enabled = not M.enabled
    vim.notify("which-key 尚未就绪，无法切换菜单语言", vim.log.levels.WARN)
    return
  end
  vim.notify(M.enabled and "界面语言：中文" or "界面语言：English", vim.log.levels.INFO)
end

---等待 which-key 完成 setup 后再应用（其 setup 是异步的）
local function apply_when_ready(attempts)
  if M.apply() then
    return
  end
  if attempts > 0 then
    vim.defer_fn(function()
      apply_when_ready(attempts - 1)
    end, 50)
  else
    vim.notify_once("which-key 未就绪，中文菜单未应用", vim.log.levels.WARN)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    group = vim.api.nvim_create_augroup("kickstart-l10n", { clear = true }),
    callback = function()
      vim.schedule(function()
        apply_when_ready(100)
      end)
    end,
  })

  vim.keymap.set("n", "<leader>uC", function()
    require("config.l10n").toggle()
  end, { desc = "切换界面语言（中/英）" })
end

return M
