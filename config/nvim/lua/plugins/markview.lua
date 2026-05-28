-- Markdown preview rendering inside buffers.
-- https://github.com/OXY2DEV/markview.nvim

local gh = require('config.util').gh

vim.pack.add { gh 'OXY2DEV/markview.nvim' }

require('markview').setup {
  preview = {
    hybrid_modes = { 'n' },
    headings = { shift_width = 0 },
  },
}
