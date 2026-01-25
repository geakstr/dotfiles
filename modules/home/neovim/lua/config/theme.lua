local M = {}
local colors = require("config.colors")

M.current_theme = nil

function M.get_system_theme()
  local home = os.getenv("SUDO_USER") and "/home/" .. os.getenv("SUDO_USER") or os.getenv("HOME")
  local f = io.open(home .. "/.local/state/theme", "r")
  if f then
    local theme = f:read("*l")
    f:close()
    if theme == "light" then return "light" end
  end
  return "dark"
end

function M.apply_dark()
  local c = colors.nord
  vim.o.background = "dark"
  pcall(vim.cmd.colorscheme, "nord")
  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = c.fgMuted, bg = "NONE" })
  M.current_theme = "dark"
end

function M.apply_light()
  local c = colors.paper
  vim.o.background = "light"
  vim.cmd("highlight clear")
  vim.api.nvim_set_hl(0, "Normal", { fg = c.fg, bg = c.bg })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = c.fg, bg = c.bgAlt })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = c.borderInactive, bg = c.bgAlt })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = c.bg })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = c.bgHighlight, bg = c.bg })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = c.borderInactive, bg = c.bg })
  vim.api.nvim_set_hl(0, "VertSplit", { fg = c.borderInactive, bg = c.bg })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = c.bgHighlight })
  vim.api.nvim_set_hl(0, "CursorColumn", { bg = c.bgHighlight })
  vim.api.nvim_set_hl(0, "LineNr", { fg = c.bgActive, bg = c.bg })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = c.fgMuted, bg = c.bg })
  vim.api.nvim_set_hl(0, "Visual", { bg = c.bgHover })
  vim.api.nvim_set_hl(0, "VisualNOS", { bg = c.bgHover })
  vim.api.nvim_set_hl(0, "Pmenu", { fg = c.fg, bg = c.bgAlt })
  vim.api.nvim_set_hl(0, "PmenuSel", { fg = c.fg, bg = c.bgHighlight })
  vim.api.nvim_set_hl(0, "PmenuSbar", { bg = c.bgHighlight })
  vim.api.nvim_set_hl(0, "PmenuThumb", { bg = c.fgMuted })
  vim.api.nvim_set_hl(0, "StatusLine", { fg = c.fg, bg = c.bgAlt })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = c.fgMuted, bg = c.bgAlt })
  vim.api.nvim_set_hl(0, "TabLine", { fg = c.fgMuted, bg = c.bgAlt })
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = c.bgAlt })
  vim.api.nvim_set_hl(0, "TabLineSel", { fg = c.fg, bg = c.bg })
  vim.api.nvim_set_hl(0, "Comment", { fg = c.fgMuted, italic = true })
  vim.api.nvim_set_hl(0, "String", { fg = c.green })
  vim.api.nvim_set_hl(0, "Number", { fg = c.blue })
  vim.api.nvim_set_hl(0, "Keyword", { fg = c.fg, bold = true })
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { fg = c.fg, bg = c.bg })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { fg = c.fg, bg = c.bg })
  M.current_theme = "light"
end

function M.apply()
  if M.get_system_theme() == "light" then M.apply_light() else M.apply_dark() end
end

function M.check()
  if M.get_system_theme() ~= M.current_theme then M.apply() end
end

function M.start_watcher()
  local timer = vim.loop.new_timer()
  timer:start(1000, 1000, vim.schedule_wrap(function() M.check() end))
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      M.apply()
      M.start_watcher()
    end, 50)
  end,
})

return M
