-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.python-ruff" },
  { import = "astrocommunity.pack.typst" },
  { import = "astrocommunity.motion.leap-nvim" },
  { import = "astrocommunity.motion.nvim-surround" },
  { import = "astrocommunity.search.nvim-hlslens" },
  { import = "astrocommunity.scrolling.neoscroll-nvim" },
  { import = "astrocommunity.media.vim-wakatime" },
  { import = "astrocommunity.markdown-and-latex.markview-nvim" },
  { import = "astrocommunity.markdown-and-latex.vimtex" },
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.completion.avante-nvim" },
  { import = "astrocommunity.completion.cmp-latex-symbols" },
}
