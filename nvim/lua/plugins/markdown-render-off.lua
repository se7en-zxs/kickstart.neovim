-- 关闭 Markdown 富文本渲染。
--
-- LazyVim 的 markdown extra（extras.lang.markdown）会引入
-- render-markdown.nvim，它会把标题、加粗、链接等 Markdown 记号
-- 渲染成富文本样式。
--
-- 本配置用 enabled = false 禁用该插件，让 Markdown 以原始源码
-- 形式显示，便于直接编辑和查看精确的 Markdown 语法。
-- lazy.nvim 会将该 spec（本目录晚于 LazyVim extra 加载）与
-- extra 引入的同一插件 spec 合并，enabled = false 覆盖为关闭。
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
  },
}