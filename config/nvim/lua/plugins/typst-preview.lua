vim.pack.add { 'https://github.com/chomosuke/typst-preview.nvim' }
require('typst-preview').setup {}

vim.keymap.set('n', '<leader>p', '<Cmd>TypstPreview<CR>', { desc = 'Typst preview' })
