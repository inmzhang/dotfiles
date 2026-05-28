-- Edit directories like buffers.
-- https://github.com/stevearc/oil.nvim

vim.pack.add { 'https://github.com/stevearc/oil.nvim' }

require('oil').setup {
  default_file_explorer = true,
  columns = {
    'icon',
  },
  view_options = {
    show_hidden = true,
  },
}

vim.keymap.set('n', '<leader>e', '<Cmd>Oil<CR>', { desc = 'Open parent directory', silent = true })
