-- kickstart.neovim 入口
--
-- 加载顺序：
--   1. LazyVim 会在 lazy.nvim 启动前自动加载 lua/config/options.lua
--      （中文消息、文件编码等基础选项都在那里设置）
--   2. lua/config/lazy.lua 引导 lazy.nvim 并加载 LazyVim 与自定义插件
--   3. lua/config/l10n.lua 在 which-key 就绪后应用中文菜单
require("config.lazy")
require("config.l10n").setup()
-- 自定义键位（config/keymaps.lua），在 LazyVim 与语言模块就绪后加载
require("config.keymaps")
