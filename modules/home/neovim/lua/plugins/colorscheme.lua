return {
  -- Nord (dark theme)
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.nord_contrast = true
      vim.g.nord_borders = true
      vim.g.nord_italic = false
      vim.g.nord_bold = false
    end,
  },
  -- Paper (light theme) is defined directly in auto-dark-mode.lua
}
