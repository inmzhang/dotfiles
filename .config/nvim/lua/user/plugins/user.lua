return {

  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
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
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "NoahTheDuke/vim-just",
    event = { "BufReadPre", "BufNewFile" },
    ft = { "\\cjustfile", "*.just", ".justfile" },
  },
  {
    "hrsh7th/nvim-cmp",
    -- add cmp latex symbols for easier julia editing
    dependencies = { "kdheepak/cmp-latex-symbols" },
    opts = function(_, opts)
      if not opts.sources then opts.sources = {} end
      table.insert(opts.sources, { name = "latex_symbols", priority = 700 })
    end,
  },
  {
    "catppuccin/nvim",
    optional = true,
    opts = { integrations = { harpoon = true } },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "mbbill/undotree",
    keys = {
      { "<leader>fu", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
    },
  },
}
