--- HBuilderX Push Light — 自定义 Neovim 主题插件
-- 使用方式：
--   · 本地插件目录：nvim/lua/custom-theme/hbx-push-light
--     ├── colors/hbx-push-light.lua   ← :colorscheme 入口（调用实现）
--     └── plugin/                     ←（预留，可放自动触发）
--   · 实现模块：nvim/lua/custom/colors/hbx_push_light.lua
--   · 颜色依据：docs/hbuilderx-push-light-theme.md
--
-- 参照 LazyVim 约定：先声明主题插件，再通过 LazyVim/LazyVim 的 opts.colorscheme
-- 设为默认主题（优先级高，先于默认 tokyonight 加载）。

return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/custom-theme/hbx-push-light",
    name = "hbx-push-light",
    priority = 1000,
    lazy = true,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "hbx-push-light",
    },
  },
}