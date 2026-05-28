-- Search and replace with a live preview.
-- https://github.com/chrisgrieser/nvim-rip-substitute

vim.pack.add { 'https://github.com/chrisgrieser/nvim-rip-substitute' }

vim.keymap.set({ 'n', 'x' }, '<leader>sS', function() require('rip-substitute').sub() end, {
  desc = '[S]earch rip [S]ubstitute',
})
