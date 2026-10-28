-- Markdown 工具配置
--
-- markdownlint 默认每行 80 字符，长中文段落会频繁触发 MD013。
-- 配置文件放在 Neovim 配置根目录，通过 --config 显式传入，
-- 这样无论当前工作目录在哪，都会使用统一的 140 列限制。
local md_config = vim.fn.stdpath("config") .. "/.markdownlint-cli2.jsonc"

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", md_config },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", md_config },
        },
      },
    },
  },
}
