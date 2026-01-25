local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

autocmd("BufWritePre", {
  group = augroup("FormatOnSave", { clear = true }),
  callback = function() vim.lsp.buf.format({ async = false }) end,
})

autocmd("TextYankPost", {
  group = augroup("HighlightYank", { clear = true }),
  callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 }) end,
})

autocmd("VimResized", {
  group = augroup("ResizeSplits", { clear = true }),
  callback = function() vim.cmd("tabdo wincmd =") end,
})

autocmd("FileType", {
  group = augroup("CloseWithQ", { clear = true }),
  pattern = { "help", "lspinfo", "man", "qf", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

autocmd("BufReadPost", {
  group = augroup("LastLocation", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = augroup("CheckExternalChanges", { clear = true }),
  command = "checktime",
})

