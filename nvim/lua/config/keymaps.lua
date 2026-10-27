-- 自定义键位
-- LazyVim 已提供大量默认键位，建议先按 <leader>? 查看当前缓冲区可用键位，
-- 或查阅 https://lazyvim.github.io/keymaps

local map = vim.keymap.set

-- 清除搜索高亮（搜索后按 Esc 立即取消高亮）
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "清除搜索高亮" })

-- 在插入模式下用 jk 退出到普通模式（可选，按需启用）
-- map("i", "jk", "<Esc>", { desc = "退出插入模式" })

-- 切换界面语言（中/英）的键位在 lua/config/l10n.lua 中注册，
-- 对应 <leader>uC，归入 <leader>u（界面）菜单。
