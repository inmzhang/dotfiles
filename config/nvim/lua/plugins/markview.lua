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

-- Checkbox toggling. Requiring the module registers the `:Checkbox` command;
-- setup() only overrides defaults, so we skip it and keep the shipped states.
-- ponytail: default state list is fine, tweak only if the extra states matter.
require 'markview.extras.checkboxes'

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  desc = 'Markdown checkbox toggle mapping',
  callback = function(args) vim.keymap.set({ 'n', 'x' }, '<leader>tc', '<Cmd>Checkbox toggle<CR>', { buffer = args.buf, desc = '[T]oggle [c]heckbox' }) end,
})
