-- 安装 LazyVim 默认需要的 Treesitter 解析器
-- 用法：nvim --headless "+luafile scripts/treesitter-install.lua" "+qa!"
--
-- 说明：LazyVim 首次打开时也会自动安装，但这一步放在安装脚本里可以：
--   1. 提前暴露网络/编译问题
--   2. 让首次打开 nvim 就有完整高亮
local langs = {
  "bash",
  "c",
  "diff",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "printf",
  "python",
  "query",
  "regex",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

local ok, task = pcall(function()
  return require("nvim-treesitter").install(langs, { summary = true })
end)
if not ok or not task then
  io.stderr:write("TS_SKIP: nvim-treesitter 未安装\n")
  os.exit(1)
end

local done = false
task:await(function()
  done = true
end)

if vim.wait(600000, function()
  return done
end, 500) then
  io.stdout:write("TS_OK\n")
else
  io.stderr:write("TS_TIMEOUT: 解析器安装超时，请在 nvim 中执行 :TSUpdate\n")
  os.exit(1)
end
