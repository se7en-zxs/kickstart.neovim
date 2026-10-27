-- 界面语言（中/英）统一开关
--
-- 覆盖四层汉化：
--   * Neovim 内置消息：运行时 :language 切换，无需重启
--   * which-key 分组名：wk.add() 覆盖
--   * 启动页 dashboard 按钮：修改 Snacks.config 后重绘
--   * lualine 模式名：fmt 每次渲染时读取当前状态
--
-- 选择会写入 stdpath("state")/kickstart-l10n.json，重启后保持。
-- 未收录的插件/键位描述保持原样，避免误译。
local M = {}

-- ============================================================================
-- 语言状态（持久化）
-- ============================================================================
local state_file = vim.fn.stdpath("state") .. "/kickstart-l10n.json"

local function load_enabled()
  local f = io.open(state_file, "r")
  if not f then
    return nil
  end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, raw)
  if ok and type(data) == "table" and type(data.zh) == "boolean" then
    return data.zh
  end
  return nil
end

local function save_enabled(zh)
  local ok, err = pcall(function()
    local f = assert(io.open(state_file, "w"))
    f:write(vim.json.encode({ zh = zh }))
    f:close()
  end)
  if not ok then
    vim.notify("无法保存界面语言设置：" .. tostring(err), vim.log.levels.WARN)
  end
end

--- true = 中文界面，false = English
M.enabled = load_enabled()
if M.enabled == nil then
  M.enabled = true
end

-- ============================================================================
-- 1. 内置消息（gettext）
-- ============================================================================
-- 英文优先用真实的 en_US，其次 C.UTF-8 / C（一定存在）。
-- 切换 :language 会立即影响后续产生的报错与提示，不需要重启。
M.locales = {
  zh = { "zh_CN.utf8", "zh_CN.UTF-8", "zh_CN" },
  en = { "en_US.utf8", "en_US.UTF-8", "C.UTF-8", "C" },
}

---把内置消息切换为当前语言
---@param opts? { notify?: boolean }
---@return boolean 是否切换成功
function M.apply_locale(opts)
  opts = opts or {}
  for _, locale in ipairs(M.enabled and M.locales.zh or M.locales.en) do
    if pcall(vim.cmd, "language " .. locale) then
      vim.g.l10n_locale = locale
      vim.g.l10n_ui = M.enabled
      vim.o.langmenu = M.enabled and "zh_CN" or "en_US"
      return true
    end
  end
  if opts.notify and M.enabled then
    vim.notify_once(
      "未找到 Neovim 中文语言包（nvim.mo），内置消息将保持英文。\n"
        .. "可运行 scripts/install.sh 重新安装，或查看 docs/troubleshooting.md。",
      vim.log.levels.WARN
    )
  end
  return false
end

-- ============================================================================
-- 2. which-key 分组名
-- ============================================================================
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
  { "<leader>uM", zh = "切换界面语言（中/英）", en = "Toggle UI language (zh/en)", mode = { "n" } },
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

-- ============================================================================
-- 3. 启动页 dashboard
-- ============================================================================
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
M.dashboard.en = {}
for zh, en in pairs(M.dashboard.zh) do
  M.dashboard.en[en] = zh
end

---把单个 dashboard 文案转换成当前语言
---@param desc string
---@return string
function M.dashboard_desc(desc)
  if M.enabled then
    return M.dashboard.zh[desc] or desc
  end
  return M.dashboard.en[desc] or desc
end

---把当前语言应用到 dashboard（启动页正开着时立即重绘）
---@return boolean
function M.apply_dashboard()
  local ok, Snacks = pcall(require, "snacks")
  if not ok or type(Snacks.config) ~= "table" then
    return false
  end
  local conf = Snacks.config.dashboard
  local preset = conf and conf.preset
  if not preset or not preset.keys then
    return false
  end
  for _, item in ipairs(preset.keys) do
    if item.desc then
      item.desc = M.dashboard_desc(item.desc)
    end
  end

  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "snacks_dashboard" then
    pcall(function()
      require("snacks.dashboard").open({ buf = buf, win = vim.api.nvim_get_current_win() })
    end)
  end
  return true
end

-- ============================================================================
-- 4. lualine 模式名
-- ============================================================================
M.modes_zh = {
  NORMAL = "普通",
  INSERT = "插入",
  VISUAL = "可视",
  ["V-LINE"] = "可视行",
  ["V-BLOCK"] = "可视块",
  REPLACE = "替换",
  ["V-REPLACE"] = "替换",
  COMMAND = "命令",
  TERMINAL = "终端",
  SELECT = "选择",
  ["S-LINE"] = "选择行",
  ["S-BLOCK"] = "选择块",
  ["OP-PENDING"] = "等待操作",
  CONFIRM = "确认",
}

---lualine mode 组件每次渲染都会调用，因此切换后无需重新 setup
---@param mode string
---@return string
function M.mode(mode)
  if not M.enabled then
    return mode
  end
  return M.modes_zh[mode] or mode
end

-- ============================================================================
-- 切换
-- ============================================================================
---在中/英文界面之间切换（消息、菜单、启动页、状态栏一起切换）
function M.toggle()
  M.enabled = not M.enabled
  save_enabled(M.enabled)

  M.apply_locale()
  M.apply()
  M.apply_dashboard()
  pcall(function()
    require("lualine").refresh()
  end)

  vim.notify(
    M.enabled and "界面语言：中文（消息 / 菜单 / 启动页 / 状态栏）"
      or "UI language: English (messages / menus / dashboard / statusline)",
    vim.log.levels.INFO
  )
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
    vim.notify_once("which-key 未就绪，菜单语言未应用", vim.log.levels.WARN)
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

  vim.keymap.set("n", "<leader>uM", function()
    require("config.l10n").toggle()
  end, { desc = "切换界面语言（中/英）" })
end

return M
