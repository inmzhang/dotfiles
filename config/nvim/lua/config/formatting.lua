local gh = require('config.util').gh

vim.pack.add { gh 'stevearc/conform.nvim' }

require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    local enabled_filetypes = { json = true, jsonc = true, lua = true }
    if enabled_filetypes[vim.bo[bufnr].filetype] then
      return { timeout_ms = 1000 }
    end
    return nil
  end,
  default_format_opts = {
    lsp_format = 'fallback',
  },
  formatters_by_ft = {
    json = { 'prettier' },
    jsonc = { 'prettier' },
    lua = { 'stylua' },
    python = { 'ruff_format' },
    typst = { 'typstyle' },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end,
  { desc = '[F]ormat buffer' })
