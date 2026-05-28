-- Paste clipboard images into the current buffer.
-- https://github.com/HakonHarnes/img-clip.nvim

vim.pack.add { 'https://github.com/HakonHarnes/img-clip.nvim' }

require('img-clip').setup {
  default = {
    prompt_for_file_name = true,
    drag_and_drop = {
      insert_mode = true,
    },
    use_absolute_path = vim.fn.has 'win32' == 1,
    dir_path = 'images',
  },
}

vim.keymap.set('n', '<leader>P', '<Cmd>PasteImage<CR>', { desc = 'Paste image from system clipboard' })
