return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    cmd = "Telescope",
    keys = {
      -- File pickers (like VS Code Ctrl+P)
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },

      -- Command palette (like VS Code Ctrl+Shift+P)
      { "<leader>p", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader><leader>", "<cmd>Telescope commands<cr>", desc = "Commands" },

      -- Search
      { "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "Search word" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Search grep" },

      -- Git
      { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git commits" },
      { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git status" },

      -- LSP
      { "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>lr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
    },
    opts = {
      defaults = {
        prompt_prefix = " ",
        selection_caret = " ",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },
        },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<Esc>"] = "close",
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
          file_ignore_patterns = { "^.git/", "node_modules" },
        },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },
}
