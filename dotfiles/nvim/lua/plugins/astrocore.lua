-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 },          -- set global limits for large files for disabling features like treesitter
      autopairs = true,                                          -- enable autopairs at start
      cmp = true,                                                -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true,                                       -- highlight URLs at start
      notifications = true,                                      -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = {              -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true,     -- sets vim.opt.number
        spell = false,     -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = false,      -- sets vim.opt.wrap
        conceallevel = 2,  -- sets vim.opt.conceallevel
        colorcolumn = "80", -- sets vim.opt.colorcolumn
        scrolloff = 10,    -- sets vim.opt.scrolloff
      },
      g = {                -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
        vimtex_view_method = "general",
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- navigate buffer tabs with `H` and `L`
        L = {
          function()
            require("astrocore.buffer").nav(vim.v.count1)
          end,
          desc = "Next buffer",
        },
        H = {
          function()
            require("astrocore.buffer").nav(-vim.v.count1)
          end,
          desc = "Previous buffer",
        },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(function(bufnr)
              require("astrocore.buffer").close(bufnr)
            end)
          end,
          desc = "Close buffer from tabline",
        },

        ["Y"] = { "^vg_y", desc = "yank line without head and tail whitespace" },

        -- Clear highlights on search when pressing <Esc> in normal mode
        ["<esc>"] = { ":nohlsearch<cr>", desc = "Clear highlights on search" },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        -- ["<Leader>b"] = { desc = "Buffers" },

        -- setting a mapping to false will disable it
        -- ["<C-S>"] = false,

        ["<Leader>zp"] = {
          function()
            require("../utils/zotero").zotero_papers()
          end,
          desc = "Find papers in Zotero storage",
        },
      },
      t = {
        -- setting a mapping to false will disable it
        ["<esc>"] = { "<C-\\><C-n>", desc = "back to normal mode from vim terminal" },
        ["jk"] = { "<C-\\><C-n>", desc = "back to normal mode from vim terminal" },
      },
    },
  },
}
