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
					vim.ui.open(item.file)
					picker:close()
				end,
			},
		}, opts or {}))
	end,
}
