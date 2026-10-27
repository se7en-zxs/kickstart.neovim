-- 插件级汉化：dashboard 按钮 + lualine 模式名
-- which-key 分组名由 lua/config/l10n.lua 负责。
return {
  {
    "snacks.nvim",
    opts = function(_, opts)
      local preset = opts.dashboard and opts.dashboard.preset
      if not preset or not preset.keys then
        return
      end
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
      for _, item in ipairs(preset.keys) do
        item.desc = zh[item.desc] or item.desc
      end

      -- 启动页底部加一句中文标语（保留 LazyVim 原有 ASCII 头图）
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
      local mode_zh = {
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
      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        {
          "mode",
          fmt = function(str)
            return mode_zh[str] or str
          end,
        },
      }
    end,
  },
}
