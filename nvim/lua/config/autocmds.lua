-- 自动命令
-- 参考：https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- 复制时短暂高亮，提示“已复制”
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "复制后高亮选区",
  group = vim.api.nvim_create_augroup("kickstart-yank-highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})
