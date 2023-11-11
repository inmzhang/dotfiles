return {
  -- Add the community repository of plugin specifications
  "AstroNvim/astrocommunity",
  -- example of imporing a plugin, comment out to use it or add your own
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.haskell" },
  { import = "astrocommunity.completion.copilot-lua" },
  { import = "astrocommunity.motion.leap-nvim" },
  { import = "astrocommunity.motion.nvim-surround" },
  { import = "astrocommunity.markdown-and-latex.markdown-preview-nvim" },
  { import = "astrocommunity.search.nvim-hlslens" },
  { import = "astrocommunity.editing-support.todo-comments-nvim" },
  { import = "astrocommunity.scrolling.neoscroll-nvim" },
  { import = "astrocommunity.media.vim-wakatime" },
  { import = "astrocommunity.media.pets-nvim" },
  { import = "astrocommunity.editing-support.suda-vim" },
  { import = "astrocommunity.colorscheme.catppuccin" },
  {
    "giusgad/pets.nvim",
    opts = {
      row = 4,
      default_pet = "crab",
      default_style = "red",
      random = false,
    },
  },
  {
    "copilot.lua",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<M-j>",
          accept_word = "<M-k>",
          accept_line = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
    },
  },
  {
    "kylechui/nvim-surround",
    opts = {
      keymaps = {
        insert = "<C-g>s",
        insert_line = "<C-g>S",
        normal = "ys",
        normal_cur = "yss",
        normal_line = "yS",
        normal_cur_line = "ySS",
        visual = "<M-s>",
        visual_line = "<M-S>",
        delete = "ds",
        change = "cs",
      },
    },
  },
}
