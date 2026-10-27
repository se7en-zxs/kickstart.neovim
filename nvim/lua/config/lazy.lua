-- lazy.nvim 引导
-- LazyVim 官方 starter 结构：https://github.com/LazyVim/starter
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "克隆 lazy.nvim 失败：\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\n检查网络或代理设置后按任意键退出……" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- 加载 LazyVim 本体及其默认插件
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- 加载本仓库的自定义插件与覆盖项（lua/plugins/*.lua）
    { import = "plugins" },
  },
  defaults = {
    -- 自定义插件默认立即加载；熟悉 lazy.nvim 后可改为 true 全部延迟加载
    lazy = false,
    -- 保持 false：很多插件的“稳定版”过旧，容易与最新 Neovim 不兼容
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- 定期检查插件更新
    notify = false, -- 不在右下角弹更新提示
  },
  rocks = {
    -- 本项目不依赖 luarocks；关闭 hererocks 可避免 :checkhealth 报错
    enabled = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
