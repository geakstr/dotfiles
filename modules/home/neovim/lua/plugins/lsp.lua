return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
  },

  {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Diagnostic display config
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "single" },
      })

      -- Start with diagnostics hidden
      vim.diagnostic.hide()

      local waiting_for_diagnostics = {}

      -- On save, hide old and wait for fresh diagnostics from LSP
      vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          vim.diagnostic.reset(nil, bufnr)  -- Clear old diagnostics completely
          waiting_for_diagnostics[bufnr] = true
        end,
      })

      -- Show only when LSP sends fresh diagnostics
      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function(args)
          local bufnr = args.buf
          if waiting_for_diagnostics[bufnr] then
            waiting_for_diagnostics[bufnr] = nil
            vim.diagnostic.show(nil, bufnr)
          end
        end,
      })

      -- Hide diagnostics when editing
      vim.api.nvim_create_autocmd({ "InsertEnter", "TextChanged" }, {
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          waiting_for_diagnostics[bufnr] = nil
          vim.diagnostic.hide(nil, bufnr)
        end,
      })

      -- Format on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function()
          vim.lsp.buf.format({ async = false })
        end,
      })

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buffer = args.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
          end

          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
          map("n", "gr", vim.lsp.buf.references, "Go to references")
          map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
          map("n", "<leader>cf", vim.lsp.buf.format, "Format")
          map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
          map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
          map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
        end,
      })

      -- rust-analyzer config (using new vim.lsp.config API)
      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              features = "all",
            },
            check = {
              command = "clippy",
            },
          },
        },
      })

      -- Enable language servers
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("ts_ls")
      vim.lsp.enable("nil_ls")
    end,
  },
}
