-- Prefer user wrappers for apps launched by Hyprland.
local local_bin = (os.getenv("HOME") or "") .. "/.local/bin"
local path = {}
for entry in (os.getenv("PATH") or ""):gmatch("[^:]+") do
  if entry ~= local_bin then table.insert(path, entry) end
end
table.insert(path, 1, local_bin)
hl.env("PATH", table.concat(path, ":"))

-- Extra autostart processes.
-- o.launch_on_start("my-service")
