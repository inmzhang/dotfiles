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
					local name = fs.basename(item.file):gsub("%.%w+$", "")
					vim.fn.setreg("+", name)
					if opts and opts.copy_without_open then
						vim.notify("Copy to clipboard: " .. string.format("%q", name))
						picker:close()
						return
					end
					vim.ui.open(item.file)
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
	zotero_cite_key = function(opts)
		-- 1. locate the .bib file ─ search upward starting at CWD
		local bib_path = vim.fs.find({ "zotero.bib" }, { upward = true })[1]
		if not bib_path then
			error("zotero.bib not found in current or any parent directory")
		end

		-- 2. read whole file
		local fh = assert(io.open(bib_path, "r"))
		local bib_contents = fh:read("*a")
		fh:close()

		-- 3. very small parser: grab key and title from each entry
		local entries = {}
		for key, body in bib_contents:gmatch("@%w+%s*{%s*([%w%-%_%.:]+)%s*,(.-)}%s*[\n\r]") do
			-- pick up `title = {...}` or `title = "..."`, allowing newlines
			local title_block = body:match("[Tt][Ii][Tt][Ll][Ee]%s*=%s*(%b{})")
					or body:match('[Tt][Ii][Tt][Ll][Ee]%s*=%s*"(.-)"')
			if key and title_block then
				-- strip surrounding braces or quotes
				local title = title_block:gsub('[{}"]', "")
				table.insert(entries, { key = "@" .. key, title = title, text = title })
			end
		end
		if vim.tbl_isempty(entries) then
			error("No cite‑able entries with titles were found in " .. bib_path)
		end

		-- 4. launch Snacks picker over titles
		Snacks.picker(vim.tbl_deep_extend("force", {
			title = "Zotero Cite Keys",
			items = entries,
			layout = {
				preset = "default",
				preview = false,
			},
			format = function(item, _)
				return {
					{ string.format("%s  ⟨%s⟩", item.title, item.key) },
				}
			end,
			actions = {
				confirm = function(picker, item)
					vim.api.nvim_set_current_win(picker.main)
					local cite = item.key
					local row, col = unpack(vim.api.nvim_win_get_cursor(0))
					local line = vim.api.nvim_get_current_line()
					local new_line = line:sub(1, col) .. cite .. line:sub(col + 1)
					vim.api.nvim_set_current_line(new_line)
					vim.api.nvim_win_set_cursor(0, { row, col + #cite })
					picker:close()
				end,
			},
		}, opts or {}))
	end,
}
