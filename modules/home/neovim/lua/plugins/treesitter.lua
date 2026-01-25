return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

      -- Install parsers synchronously on first run
      local parsers = { "rust", "lua", "javascript", "typescript", "tsx", "json", "yaml", "toml", "bash", "nix", "python", "go", "html", "css", "markdown", "markdown_inline", "vim", "vimdoc" }
      require("nvim-treesitter").install(parsers)

      -- Enable highlighting for all filetypes
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
