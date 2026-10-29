--- HBuilderX Push Light — Neovim 主题（Light）
-- 依据 VSCode 扩展 ZQun.theme-hbuilderx-push-light（HBuilderX Push Light）制作。
-- 配色逐项取自该扩展 themes/hbuilderx-soft-green-light-color-theme.json，
-- 本源数据清单见技术文档 docs/hbuilderx-push-light-theme.md。
--
-- 注册与启用方式见 nvim/lua/plugins/hbx-push-light.lua。
-- 手动打开：`:colorscheme hbx-push-light`

local M = {}

-- ============================================================================
-- 基础调色板（色值来源见上方文档）
-- ============================================================================
local pal = {
  bg          = "#fffae8", -- editor.background（画布主背景，米白）
  bg_panel    = "#fbf5e1", -- activityBar.background（稍深米黄）
  bg_soft     = "#eee8d5", -- editor.selectionBackground / widget
  bg_curline  = "#e8dfc4", -- editor.lineHighlightBackground（当前行）
  fg          = "#404b53", -- editor.foreground（深灰蓝正文）
  fg_muted    = "#586e75", -- statusBar / sideBarTitle 前景
  fg_dim      = "#9f9371", -- editorLineNumber.foreground（行号）
  sel         = "#eee8d5", -- 选区背景
  cursor      = "#41a863", -- 光标（强调绿）
  guide       = "#d8ca9e", -- 缩进指引（活动）
  guide_soft  = "#f7f2e4", -- 缩进指引（常态）
  accent      = "#41a863", -- focusBorder / activeBorder（绿）
  yellow      = "#b58900", -- badge / button（黄）
  cyan        = "#56B6C2", -- 算术/比较运算符
  purple      = "#9B3AFF", -- Number
  magenta     = "#cd0084", -- constant
  red         = "#CA004B", -- 逻辑运算符 / support.function
}

-- ============================================================================
-- ANSI 终端 16 色：行 1 普通、行 2 亮色
-- 说明：Lazygit 的「暂存文件」与「commit 哈希」用的是硬编码的基础 ANSI 绿(2)/黄(3)
-- （并非 gui.theme 可配），经 Neovim 终端调色板渲染。原 2=#097e00、10=#74fa61 等
-- 在浅色背景上过亮，故统一压深为可读深绿/深棕，与 diff 新增(#1a7f37)/tag(#8a5a00)一致。
-- ============================================================================
local term = {
  { "#000000", "#fd6c67", "#1a7f37", "#8a5a00",
    "#5597ef", "#fe76ff", "#39cbcc", "#bbbbbb" },
  { "#686868", "#b8493f", "#1a7f37", "#8a5a00",
    "#7faff4", "#c23b8c", "#2a9d9d", "#f1f1f1" },
}

-- ============================================================================
-- 语法高亮（tokenColors 语义映射，见 docs 表三）
-- ============================================================================
local syn = {
  comment     = "#95A3AB", -- comment
  keyword     = "#577909", -- keyword（粗体）
  storage     = "#473cc4", -- storage（粗体）
  funcName    = "#DB7800", -- entity.name.function
  funcArg     = "#A28D00", -- entity.name.function.argument
  funcName2   = "#AE7A00", -- 次级 function name
  string      = "#348f85", -- string 主色
  string_def  = "#2aa198", -- 引号
  number      = "#9B3AFF", -- Number
  constant    = "#cd0084", -- constant
  type        = "#4488d5", -- entity.name.type / support.class
  variable    = "#404b54", -- variable / variable.parameter
  parameter   = "#404b54",
  operator    = "#839e00", -- keyword.operator 一般
  tag         = "#2369B6", -- html/xml 标签
  property    = "#934b3c", -- property
  attribute   = "#cb2d01", -- attribute
  support     = "#3c7a03", -- support（预定义）
  support_fn  = "#CA004B", -- support.function
  namespace   = "#3f4b53", -- entity.name.type.namespace
  punctuation = "#404b53",
}

-- ============================================================================
-- 快捷设置 highlight 组
-- ============================================================================
local function hl(name, val)
  vim.api.nvim_set_hl(0, name, val)
end

-- ============================================================================
-- 界面（UI）高亮
-- ============================================================================
local function ui()
  hl("Normal",          { fg = pal.fg, bg = pal.bg })
  hl("NormalFloat",     { fg = pal.fg, bg = pal.bg_soft })
  hl("FloatBorder",     { fg = pal.guide, bg = pal.bg_soft })
  hl("NormalNC",        { fg = pal.fg, bg = pal.bg })
  hl("Cursor",          { fg = pal.bg, bg = pal.cursor })
  hl("CursorLine",      { bg = pal.bg_curline })
  hl("CursorColumn",    { bg = pal.bg_curline })
  hl("CursorLineNr",    { fg = pal.accent })
  hl("LineNr",          { fg = pal.fg_dim })
  hl("SignColumn",      { fg = pal.fg_dim, bg = pal.bg })

  -- colorcolumn 竖线；render-markdown 的行内代码/代码块背景默认链接到它
  -- 默认未定义时会继承到灰色（#9B9EA4），在浅色画布上很刺眼
  hl("ColorColumn",     { bg = pal.bg_soft })

  hl("Visual",          { bg = pal.sel })
  hl("VisualNOS",       { bg = pal.sel })
  hl("Search",          { fg = pal.bg, bg = pal.yellow })
  hl("CurSearch",       { fg = pal.bg, bg = pal.yellow })
  hl("IncSearch",       { fg = pal.bg, bg = pal.yellow })
  hl("MatchParen",      { fg = pal.fg, bold = true })
  hl("WinSeparator",    { fg = pal.guide })

  hl("Title",           { fg = pal.fg, bold = true })
  hl("Directory",       { fg = syn.type })
  hl("Underlined",      { underline = true })
  hl("Conceal",         { fg = pal.fg_dim })

  -- Popup 菜单
  hl("Pmenu",           { bg = pal.bg_soft })
  hl("PmenuSel",        { fg = pal.bg, bg = pal.accent })
  hl("PmenuSbar",       { bg = pal.bg_soft })
  hl("PmenuThumb",      { bg = pal.guide })
  hl("WildMenu",        { fg = pal.bg, bg = pal.accent })

  -- Tab 栏
  hl("TabLine",         { bg = pal.bg })
  hl("TabLineSel",      { fg = pal.bg, bg = pal.accent })
  hl("TabLineFill",     { bg = pal.bg })

  -- 状态栏 / 侧栏
  hl("StatusLine",       { fg = pal.fg_muted, bg = pal.bg })
  hl("StatusLineNC",     { fg = pal.fg_dim, bg = pal.bg_panel })
  hl("StatusLineTerm",   { fg = pal.fg_muted, bg = pal.bg })
  hl("StatusLineTermNC", { fg = pal.fg_dim, bg = pal.bg_panel })

  -- 缩进指引
  hl("IndentBlanklineChar", { fg = pal.guide_soft })
  hl("IndentBlanklineContextChar", { fg = pal.guide })
end

-- ============================================================================
-- 语法高亮
-- ============================================================================
local function syntax()
  -- 注释
  hl("Comment",      { fg = syn.comment })
  hl("CommentSQL",   { fg = syn.comment })

  -- 关键字与声明
  hl("Keyword",      { fg = syn.keyword, bold = true })
  hl("StorageClass", { fg = syn.storage, bold = true })
  hl("Statement",    { fg = syn.keyword })
  hl("Conditional",  { fg = syn.keyword })
  hl("Repeat",       { fg = syn.keyword })
  hl("Label",        { fg = syn.keyword })
  hl("Exception",    { fg = syn.support_fn })
  hl("PreProc",      { fg = syn.funcName })
  hl("PreCondit",    { fg = syn.funcName })
  hl("Define",       { fg = syn.keyword })
  hl("Macro",        { fg = syn.keyword })

  -- 函数
  hl("Function",     { fg = syn.funcName })
  hl("funcName",     { fg = syn.funcName })

  -- 类型 / 类
  hl("Type",         { fg = syn.type })
  hl("Typedef",      { fg = syn.type })
  hl("Structure",    { fg = syn.type })
  hl("Class",        { fg = syn.type })
  hl("Namespace",    { fg = syn.namespace })

  -- 字符串 / 字面量 / 变量
  hl("String",          { fg = syn.string })
  hl("StringDelimiter", { fg = syn.string_def })
  hl("Character",       { fg = syn.string })
  hl("Number",          { fg = syn.number })
  hl("Float",           { fg = syn.number })
  hl("Boolean",         { fg = syn.number })
  hl("Constant",        { fg = syn.constant })
  hl("Identifier",      { fg = syn.variable })
  hl("@variable",           { fg = syn.variable })
  hl("@variable.parameter", { fg = syn.parameter })

  -- 运算符
  hl("Operator",     { fg = pal.cyan })
  hl("@operator",    { fg = syn.operator })

  -- 标签 / 属性
  hl("Tag",          { fg = syn.tag, bold = true })
  hl("@tag",         { fg = syn.tag, bold = true })
  hl("@attribute",   { fg = syn.attribute })
  hl("@property",    { fg = syn.property })

  -- 支持 / 预定义
  hl("Special",        { fg = syn.support })
  hl("SpecialChar",    { fg = syn.support })
  hl("SpecialComment", { fg = syn.comment })
  hl("SpecialKey",     { fg = syn.funcName })

  -- 标点 / 分隔符
  hl("Delimiter",    { fg = syn.punctuation })

  -- LSP 诊断
  hl("DiagnosticError", { fg = syn.attribute })
  hl("DiagnosticWarn",  { fg = pal.yellow })
  hl("DiagnosticInfo",  { fg = syn.type })
  hl("DiagnosticHint",  { fg = syn.comment })

  -- 行内消息
  hl("Todo",         { fg = pal.bg, bg = pal.yellow })
  hl("Error",        { fg = syn.support_fn, bold = true })
  hl("ErrorMsg",     { fg = syn.support_fn })
  hl("WarningMsg",   { fg = pal.yellow })
end

-- ============================================================================
-- 终端颜色（:terminal / 终端缓冲）
-- ============================================================================
local function terminals()
  for _, row in ipairs(term) do
    for idx, hex in ipairs(row) do
      vim.g["terminal_color_" .. (idx - 1)] = hex
    end
  end
  hl("TermCursor",   { fg = pal.bg, bg = pal.cursor })
  hl("TermCursorNC", { fg = pal.bg, bg = pal.fg_dim })
end

-- ============================================================================
-- Git / diff
-- ============================================================================
local function git()
  local add    = term[1][3]
  local del    = term[1][2]
  local change = term[1][5]
  hl("diffAdded",   { fg = add })
  hl("diffRemoved", { fg = del })
  hl("diffChanged", { fg = change })
  hl("DiffAdd",     { fg = add, bg = pal.bg })
  hl("DiffDelete",  { fg = del, bg = pal.bg })
  hl("DiffChange",  { fg = change, bg = pal.bg })
  hl("diffOldFile", { fg = pal.fg_dim })
  hl("diffFile",    { fg = syn.funcName })
end

-- ============================================================================
-- 主入口
-- ============================================================================
function M.setup()
  vim.o.background = "light"       -- 主题类型：Light
  vim.g.colors_name = "hbx-push-light"

  ui()
  syntax()
  terminals()
  git()
end

return M