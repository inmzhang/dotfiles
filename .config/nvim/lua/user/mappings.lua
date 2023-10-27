-- Mapping data with "desc" stored directly by vim.keymap.set().
-- vim.g.magma_image_provider = "ueberzug"
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map
    -- mappings seen under group name "Buffer"
    ["<leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(
          function(bufnr) require("astronvim.utils.buffer").close(bufnr) end
        )
      end,
      desc = "Pick to close",
    },
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
    ["Y"] = { "^vg_y", desc = "yank line without head and tail whitespace" },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
    ["<esc>"] = { "<C-\\><C-n>", desc = "back to normal mode from vim terminal" },
    ["jk"] = { "<C-\\><C-n>", desc = "back to normal mode from vim terminal" },
  },
  v = {
    -- move text up and down
    ["<M-j>"] = { ":m '>+1<cr>gv=gv", desc = "Move line down" },
    ["<M-k>"] = { ":m '<-2<cr>gv=gv", desc = "Move line up" },
    -- remeber yanked text, not overwrite by the substitute
    ["p"] = {'"_dP', desc = "paste yanked text"},
  }
}
