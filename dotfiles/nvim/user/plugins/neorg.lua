return {
  "nvim-neorg/neorg",
  dependencies = { "luarocks.nvim" },
  lazy = false,
  -- tag = "*",
  config = function()
    require("neorg").setup {
      load = {
        ["core.defaults"] = {}, -- Loads default behaviour
        ["core.summary"] = {},
        ["core.concealer"] = {
          config = {
            icon_preset = "diamond",
          },
        }, -- Adds pretty icons to your documents
        ["core.export"] = {},
        ["core.itero"] = {},
        ["core.keybinds"] = {
          config = {
            hook = function(keybinds) keybinds.remap_key("norg", "i", "<M-CR>", "<C-n>") end,
          },
        },
        ["core.completion"] = {
          config = {
            engine = "nvim-cmp",
          },
        },
        ["core.dirman"] = { -- Manages Neorg workspaces
          config = {
            workspaces = {
              main = "~/neorg/main",
              root = "~/neorg",
            },
            default_workspace = "main",
          },
        },
        ["core.journal"] = {
          config = {
            workspace = "root",
          },
        },
      },
    }
  end,
}
