-- Snacks Explorer：关闭系统回收站（trash），删除文件时直接永久删除
-- 避免无桌面会话环境下 `gio trash` 调用报错（表现为删除时报 gio error）
return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      trash = false, -- 直接删除，不经系统回收站
    },
  },
}