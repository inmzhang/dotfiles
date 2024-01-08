return {
  "nvim-neorg/neorg",
  -- ft = "norg",
  lazy = false,
  build = ":Neorg sync-parsers",
  -- tag = "*",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("neorg").setup {
      load = {
        -- ["core.keybinds"] = {
        --   config = {
        --       hook = function(keybinds)
        --             keybinds.remap_key("norg", "n", "<M-CR>", "<C-j>")
        --       end,
        --   }
        -- },
        ["core.defaults"] = {}, -- Loads default behaviour
        ["core.summary"] = {},
        ["core.concealer"] = {
          config = {
            icon_preset = "diamond",
          }
        }, -- Adds pretty icons to your documents
        ["core.export"] = {},
        ["core.itero"] = {},
        ["core.completion"] = {
          config = {
            engine = "nvim-cmp",
          }
        },
        ["core.dirman"] = { -- Manages Neorg workspaces
          config = {
            workspaces = {
              main = "~/neorg",
            },
            default_workspace = "main",
          },
        },
      },
    }
  end,
}
