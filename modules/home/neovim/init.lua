-- Load core config
require("config.options")
require("config.keymaps")

-- Skip plugins when running as root (security)
local is_root = vim.loop.getuid() == 0

if not is_root then
  -- Bootstrap lazy.nvim
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  -- Setup lazy.nvim
  require("lazy").setup({
    spec = {
      { import = "plugins" },
    },
    defaults = {
      lazy = false,
    },
    install = {
      colorscheme = { "nord" },
    },
    checker = {
      enabled = false,
    },
    change_detection = {
      notify = false,
    },
  })
end

-- Load theme (works with or without plugins)
require("config.theme")
require("config.autocmds")
