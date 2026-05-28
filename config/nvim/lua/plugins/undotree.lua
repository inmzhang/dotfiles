-- Visualize and navigate undo history.
-- https://github.com/mbbill/undotree

vim.pack.add { 'https://github.com/mbbill/undotree' }

vim.keymap.set('n', '<leader>fu', '<Cmd>UndotreeToggle<CR>', { desc = 'Toggle undotree' })
