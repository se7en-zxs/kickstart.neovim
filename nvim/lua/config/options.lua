-- Neovim 基础选项
-- 本文件由 LazyVim 在 lazy.nvim 启动之前自动加载，适合放“必须尽早生效”的设置。

-- ============================================================================
-- 中文界面
-- ============================================================================
-- Neovim 的内置消息（报错、提示、:messages）由 gettext 翻译。
-- 安装脚本会把官方 zh_CN.UTF-8.po 编译成 nvim.mo，放到 Neovim 安装目录的
-- share/locale/ 下；这里只负责切换到该语言。
--
-- 注意：必须使用系统真实存在的 locale 名称。Ubuntu/Debian 上通常是
-- zh_CN.utf8（或 zh_CN.UTF-8），只写 zh_CN 可能报 E197。
local locale_ok = false
for _, locale in ipairs({ "zh_CN.utf8", "zh_CN.UTF-8", "zh_CN" }) do
  if pcall(vim.cmd, "language " .. locale) then
    vim.g.l10n_locale = locale
    locale_ok = true
    break
  end
end

if not locale_ok then
  vim.notify_once(
    "未找到 Neovim 中文语言包（nvim.mo），内置消息将保持英文。\n"
      .. "可运行 scripts/install.sh 重新安装，或查看 docs/troubleshooting.md。",
    vim.log.levels.WARN
  )
end

-- 菜单语言（GUI 菜单；终端下影响不大，但保持一致）
vim.o.langmenu = "zh_CN"

-- ============================================================================
-- 中文文件与编码
-- ============================================================================
-- 优先 UTF-8；同时兼容 Windows 常见的 GB18030/GBK 与旧版 Big5 文件。
-- 打开乱码文件时可用 :e ++enc=gb18030 手动指定。
vim.opt.fileencodings = "ucs-bom,utf-8,gb18030,gbk,big5,latin1"
vim.opt.fileformats = "unix,dos,mac"

-- ============================================================================
-- 其他常用选项
-- ============================================================================
-- 搜索时忽略大小写，但输入大写字母时区分大小写。
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 中文排版：超过窗口宽度时按“显示行”换行，而不是按单词硬折行。
-- 仅在 markdown / text 等长文文件中开启，代码文件保持 LazyVim 默认。
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})
