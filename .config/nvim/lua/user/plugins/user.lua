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
  {
    "stevearc/oil.nvim",
    keys = {
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {},
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {},
  },
  {
    "mrcjkb/haskell-tools.nvim",
    version = "^3", -- Recommended
    ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
    init = function(_, opts)
      local ht = require "haskell-tools"
      local bufnr = vim.api.nvim_get_current_buf()
      local def_opts = { noremap = true, silent = true, buffer = bufnr }
      -- haskell-language-server relies heavily on codeLenses,
      -- so auto-refresh (see advanced configuration) is enabled by default
      vim.keymap.set("n", "<space>ca", vim.lsp.codelens.run, opts)
      -- Hoogle search for the type signature of the definition under the cursor
      vim.keymap.set("n", "<space>hs", ht.hoogle.hoogle_signature, opts)
      -- Evaluate all code snippets
      vim.keymap.set("n", "<space>ea", ht.lsp.buf_eval_all, opts)
      -- Toggle a GHCi repl for the current package
      vim.keymap.set("n", "<leader>rr", ht.repl.toggle, opts)
      -- Toggle a GHCi repl for the current buffer
      vim.keymap.set("n", "<leader>rf", function() ht.repl.toggle(vim.api.nvim_buf_get_name(0)) end, def_opts)
      vim.keymap.set("n", "<leader>rq", ht.repl.quit, opts)
    end,
  },
  {
    "dfendr/clipboard-image.nvim",
    ft = "markdown",
    opts = {
      default = {
        img_dir = { "%:p:h", "img" },
        img_name = function()
          vim.fn.inputsave()
          local name = vim.fn.input "Name: "
          vim.fn.inputrestore()
          return name
        end,
      },
    },
  },
}
