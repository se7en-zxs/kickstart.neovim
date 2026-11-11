-- Neovim 基础选项
-- 本文件由 LazyVim 在 lazy.nvim 启动之前自动加载，适合放“必须尽早生效”的设置。

-- ============================================================================
-- 界面语言（中/英）
-- ============================================================================
-- 内置消息（报错、提示、:messages）由 gettext 翻译。安装脚本把官方
-- zh_CN.UTF-8.po 编译成 nvim.mo 放到 Neovim 安装目录的 share/locale/ 下。
--
-- 语言选择、locale 回退、以及 <leader>uM 运行时切换都由 config/l10n.lua 统一
-- 管理：默认中文，可切到英文，选择会持久化到 stdpath("state")。
-- 注意：locale 必须使用系统真实存在的名称，只写 zh_CN 可能报 E197。
require("config.l10n").apply_locale({ notify = true })

-- ============================================================================
-- 中文文件与编码
-- ============================================================================
-- 优先 UTF-8；同时兼容 Windows 常见的 GB18030/GBK 与旧版 Big5 文件。
-- 打开乱码文件时可用 :e ++enc=gb18030 手动指定。
vim.opt.fileencodings = "ucs-bom,utf-8,gb18030,gbk,big5,latin1"
vim.opt.fileformats = "unix,dos,mac"

-- ============================================================================
-- 格式化
-- ============================================================================
-- 关闭保存时自动格式化（LazyVim 默认为开启）。
-- 本文件在 LazyVim 默认配置之后加载，因此这里的设置会覆盖默认值。
-- 需要手动格式化时仍可使用 <leader>cf。
vim.g.autoformat = false

-- ============================================================================
-- 其他常用选项
-- ============================================================================
-- 搜索时忽略大小写，但输入大写字母时区分大小写。
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ============================================================================
-- 剪贴板（OSC 52）
-- ============================================================================
-- 让 y/p 默认读写“系统剪贴板”寄存器 +（对应 Windows 宿主机剪贴板）。
-- 系统剪贴板的实际读写交给正在运行的终端完成（OSC 52 协议），
-- 无需任何外部桥接程序（如 win32yank / clip.exe）。
-- 前提：终端必须支持并放行 OSC 52（Windows Terminal 等玳代终端支持）。
--
-- 注意：LazyVim 会把 vim.o.clipboard 延迟到 VeryLazy 事件时才恢复
-- （lazyvim/config/init.lua 中先清空、再在 VeryLazy 恢复），所以这里必须
-- 也在 VeryLazy 事件内设置，才能覆盖 LazyVim 的恢复值，避免被清空。
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    vim.opt.clipboard = "unnamedplus"
  end,
})
vim.g.clipboard = {
  name = "OSC52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}

-- 中文排版：超过窗口宽度时按“显示行”换行，而不是按单词硬折行。
-- 仅在 markdown / text 等长文文件中开启，代码文件保持 LazyVim 默认。
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})
