-- 插件级汉化：dashboard 按钮 + lualine 模式名
-- 语言状态与切换逻辑统一在 lua/config/l10n.lua。
local l10n = require("config.l10n")

return {
  {
    "snacks.nvim",
    opts = function(_, opts)
      local preset = opts.dashboard and opts.dashboard.preset
      if not preset or not preset.keys then
        return
      end
      for _, item in ipairs(preset.keys) do
        if item.desc then
          item.desc = l10n.dashboard_desc(item.desc)
        end
      end

      -- 启动页布局（保留 LazyVim 原有 ASCII 头图）
      opts.dashboard.sections = opts.dashboard.sections or {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      }
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        {
          "mode",
          -- lualine 每次重绘都会调用 fmt，切换语言后只需 refresh()
          fmt = function(str)
            return l10n.mode(str)
          end,
        },
      }
    end,
  },
}
