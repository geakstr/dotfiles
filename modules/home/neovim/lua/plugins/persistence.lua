return {
  {
    "olimorris/persisted.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("persisted").setup({
        autoload = true,
        use_git_branch = false,
        ignored_dirs = {},
      })
      require("persisted").start()
    end,
  },
}
