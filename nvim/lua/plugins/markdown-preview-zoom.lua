-- markdown-preview.nvim：浏览器预览图片/流程图缩放增强。
--
-- 背景：markdown-preview 的默认样式（app/_static/markdown.css）中
--   .markdown-body img { max-width: 100%; max-height: 100%; }
-- 会把图片/流程图限制在预览容器宽度内，且预览页本身没有缩放交互，
-- 导致大截图、PlantUML / mermaid / Graphviz 等生成的图无法放大查看细节。
--
-- 方案分两层：
--   1) CSS：用 g:mkdp_markdown_css 指向 nvim/markdown-preview.css。该文件是
--      插件默认样式的完整拷贝，仅去掉 max-height:100% 限制，并把图片光标设为
--      zoom-in 提示。markdown-preview 只允许用该变量"整体替换"默认 CSS
--      （见插件 app/routes.js）。
--   2) JS —— 插件不支持注入 JS，因此用 lazy.nvim 的 build 钩子调用
--      nvim/scripts/patch-markdown-preview.sh，把 nvim/markdown-preview-zoom.js
--      注入插件目录：复制到 app/_static/，并在 app/out/index.html 的 </body> 前
--      加 <script src="/_static/mkdp-zoom.js">。脚本在插件 安装/更新 时自动运行，
--      幂等可重跑；改动 JS 后手动执行 bash nvim/scripts/patch-markdown-preview.sh
--      重新注入。实现的是 lightbox：点击图片/流程图弹层放大，滚轮以光标为中心
--      缩放（20%~500%）、左键拖拽平移、双击复原、Esc/点击空白关闭。
--
-- 移除本 spec 即回到插件原样（无任何缩放增强）。
return {
  "iamcco/markdown-preview.nvim",
  build = "bash "  .. vim.fn.stdpath("config")  .. "/scripts/patch-markdown-preview.sh",
  init = function()
    -- 插件 app/server.js 在每次启动预览服务时读取 g:mkdp_markdown_css
    -- （见插件 app/routes.js），返回给浏览器的 /_static/markdown.css 即该文件。
    -- vim.fn.stdpath("config") = ~/.config/nvim，仓库的 nvim/ 被软链到该目录，
    -- 因此指向 ~/.config/nvim/markdown-preview.css。
    vim.g.mkdp_markdown_css = vim.fn.stdpath("config")  .. "/markdown-preview.css"
  end,
}