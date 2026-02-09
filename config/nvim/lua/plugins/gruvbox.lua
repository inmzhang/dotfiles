return {
  "sainnhe/gruvbox-material",
  lazy = false,
  priority = 1000,
  config = function()
    vim.g.gruvbox_material_foreground = "material"
    vim.g.gruvbox_material_background = "medium"
    vim.g.gruvbox_material_visual = "red background"
    vim.g.gruvbox_material_diagnostic_text_highlight = 1
    vim.g.gruvbox_material_diagnostic_line_highlight = 1
    vim.g.gruvbox_material_diagnostic_virtual_text = "colored"
    vim.g.gruvbox_material_better_performance = 1
    vim.g.gruvbox_material_enable_italic = true
  end,
}
