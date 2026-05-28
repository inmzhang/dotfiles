-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Create user command

vim.api.nvim_create_user_command("ZoteroPaper", function()
  require("./utils/snack_picker").zotero_papers()
end, {})

vim.api.nvim_create_user_command("Notes", function()
  require("./utils/snack_picker").note_taking()
end, {})
