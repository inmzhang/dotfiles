return {

  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    init = function() vim.o.background = "dark" end,
  },
  {
    "chikko80/error-lens.nvim",
    event = "BufRead",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
  },
  {
    "kaarmu/typst.vim",
    ft = "typst",
    lazy = false,
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "NoahTheDuke/vim-just",
    lazy = false,
  },
  -- {
  --   "Pocco81/auto-save.nvim",
  --     event = { "User AstroFile", "InsertEnter" },
  --     opts = {},
  -- },
}
