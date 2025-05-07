return {
  "zbirenbaum/copilot.lua",
  opts = {
    -- Disabled for integration with blink-copilot-cmp
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
}
