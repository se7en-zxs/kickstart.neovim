-- 让 LazyVim / Snacks 调用的 Lazygit 使用浅色配色方案
--
-- 背景：本机终端是浅色（Light）主题。Lazygit 默认 colorScheme=auto，
-- 在终端未明确告知时它假定「深色背景」，导致 commit 哈希、分支圆点、
-- 随机小提示等自动着色的文字用了亮色，在浅色背景下看不清。
-- 这里通过 Snacks 的 lazygit opts.config，把 gui.colorScheme 强制设为 light，
-- 并直接并入 Snacks 生成的 lazygit-theme.yml（该文件加载优先级最高），
-- 从而确保 Neovim 内打开的 Lazygit 一定以浅色方案取可读深色文字。

return {
  {
    "snacks.nvim",
    opts = function(_, opts)
      -- 只处理 lazygit 相关配置
      opts.lazygit = opts.lazygit or {}
      opts.lazygit.config = opts.lazygit.config or {}
      opts.lazygit.config.gui = opts.lazygit.config.gui or {}
      -- 强制浅色方案 → 自动着色的 commit hash / 分支圆点 / 随机提示用深色可读文字
      opts.lazygit.config.gui.colorScheme = "light"
    end,
  },
}