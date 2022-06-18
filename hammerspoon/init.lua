-- Load all config
local conf_items = {}

for item in hs.fs.dir(hs.configdir) do
  if item == 'init.lua' then goto continue end
  if not item:find('%.lua$') then goto continue end
  
  local path = ('%s/%s'):format(hs.configdir, item)
  
  local ftype = hs.fs.attributes(path, 'mode')
  if ftype ~= 'file' and ftype ~= 'link' then goto continue end
  
  if (hs.fs.attributes(path, 'permissions') or ''):sub(3, 3) ~= 'x' then
    print(('config: %q not executable; skipping'):format(item))
    goto continue
  end
  
  print(('config: adding %q'):format(item))
  table.insert(conf_items, item)
  
  ::continue::
end

table.sort(conf_items)

for _, item in ipairs(conf_items) do
  local path = ('%s/%s'):format(hs.configdir, item)
  
  local f, err = loadfile(path)
  if not f then
    print(('config: %q failed to parse: %s'):format(item, err))
    goto continue
  end
  
  local succ, err = pcall(f)
  if not succ then
    print(('config: %q failed to load: %s'):format(item, err))
  end
  
  ::continue::
end
