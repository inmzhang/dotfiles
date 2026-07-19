local M = {}

function M.gh(repo)
  return 'https://github.com/' .. repo
end

--- Project root for the current buffer (git root, else cwd).
---@return string
function M.project_root()
  local root = vim.fs.root(0, { '.git' })
  if root then return root end
  return vim.fn.getcwd()
end

--- Path of the current buffer relative to the project root.
---@return string|nil
function M.buffer_relpath()
  local abs = vim.api.nvim_buf_get_name(0)
  if abs == '' then return nil end

  abs = vim.fs.normalize(abs)
  local root = vim.fs.normalize(M.project_root())

  if vim.fs.relpath then
    local rel = vim.fs.relpath(root, abs)
    if rel then return rel end
  end

  if abs:sub(1, #root) == root then
    local rel = abs:sub(#root + 1):gsub('^/', '')
    if rel ~= '' then return rel end
  end

  return abs
end

--- Enclosing treesitter symbol name (function/class/etc.), if any.
---@return string|nil
function M.treesitter_node_name()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return nil end

  local definition_types = {
    function_declaration = true,
    function_definition = true,
    function_item = true,
    method_declaration = true,
    method_definition = true,
    class_declaration = true,
    class_definition = true,
    struct_item = true,
    enum_item = true,
    impl_item = true,
    trait_item = true,
    type_definition = true,
    interface_declaration = true,
    module = true,
    namespace_definition = true,
  }

  ---@param n TSNode
  ---@return string|nil
  local function name_of(n)
    local names = n:field 'name'
    if names and names[1] then
      local text = vim.treesitter.get_node_text(names[1], 0)
      if text and text ~= '' then return text end
    end
    return nil
  end

  local current = node
  local fallback ---@type string|nil

  while current do
    local name = name_of(current)
    if name then
      if definition_types[current:type()] then return name end
      fallback = fallback or name
    end
    current = current:parent()
  end

  if fallback then return fallback end

  if node:named() then
    local ty = node:type()
    if ty:find('identifier', 1, true) or ty == 'name' or ty == 'property_identifier' then
      local text = vim.treesitter.get_node_text(node, 0)
      if text and text ~= '' then return text end
    end
  end

  return nil
end

--- Compact review position: `{filepath}#L{line}:{node name}`
---@return string|nil
function M.review_position()
  local path = M.buffer_relpath()
  if not path then
    vim.notify('No file name for current buffer', vim.log.levels.WARN)
    return nil
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local node = M.treesitter_node_name() or '?'
  return ('%s#L%d:%s'):format(path, line, node)
end

--- Copy review position to the system clipboard.
---@return string|nil
function M.copy_review_position()
  local pos = M.review_position()
  if not pos then return nil end

  vim.fn.setreg('+', pos)
  vim.fn.setreg('"', pos)
  vim.notify('Copied: ' .. pos, vim.log.levels.INFO)
  return pos
end

---@return string
local function notes_path()
  return vim.fs.joinpath(M.project_root(), 'notes.md')
end

--- Ensure notes.md exists at the project root.
---@param path string
local function ensure_notes(path)
  if vim.fn.filereadable(path) == 0 and vim.fn.bufloaded(path) == 0 then
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile({}, path)
  end
end

--- Open project-root notes.md (create if missing).
function M.open_review_notes()
  local path = notes_path()
  ensure_notes(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

--- Append review position bullet to notes.md and place cursor after the trailing `:`.
function M.append_review_position()
  local pos = M.review_position()
  if not pos then return end

  local entry = ('- `%s`:'):format(pos)
  local path = notes_path()
  ensure_notes(path)
  vim.cmd.edit(vim.fn.fnameescape(path))

  local buf = 0
  local line_count = vim.api.nvim_buf_line_count(buf)
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  if line_count == 1 and first == '' then
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, { entry })
  else
    vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, { entry })
  end

  local last = vim.api.nvim_buf_line_count(buf)
  -- Cursor on the trailing `:` so `a` continues the note.
  vim.api.nvim_win_set_cursor(0, { last, #entry - 1 })
end

return M
