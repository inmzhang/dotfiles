local Snacks = require("snacks")
local fs = vim.fs

return {
	zotero_papers = function(opts)
		Snacks.picker.files(vim.tbl_deep_extend("force", {
			title = "Zotero Papers",
			dirs = { fs.normalize((vim.env.HOME or "") .. "/Zotero/storage") },
			ft = "pdf",
			follow = true,
			actions = {
				confirm = function(picker, item)
					vim.fn.setreg("+", fs.basename(item.file):gsub("%.%w+$", ""))
					vim.ui.open(item.file)
					picker:close()
					vim.cmd("qa")
				end,
			},
		}, opts or {}))
	end,
	note_taking = function(opts)
		Snacks.picker.files(vim.tbl_deep_extend("force", {
			title = "Note Taking",
			dirs = { fs.normalize((vim.env.HOME or "") .. "/Documents/note-taking") },
			ft = { "md", "typ" },
			follow = true,
			actions = {
				confirm = Snacks.picker.actions.jump,
			},
		}, opts or {}))
	end,
}
