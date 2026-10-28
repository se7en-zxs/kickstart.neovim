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

-- 关闭 LazyVim 在文本类文件中自动开启的英文拼写检查。
-- LazyVim 的 wrap_spell 自动命令会在 FileType 时设置 spell=true；
-- 本文件在 LazyVim 默认自动命令之后加载，因此后注册的这里会覆盖它。
-- 需要临时检查拼写时仍可用 <leader>us（Snacks 的 Spelling 开关）手动开启。
vim.api.nvim_create_autocmd("FileType", {
  desc = "关闭文本类文件的拼写检查",
  group = vim.api.nvim_create_augroup("kickstart-disable-spell", { clear = true }),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
