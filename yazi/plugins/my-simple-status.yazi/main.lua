local function spacer()
	return ui.Span(" ")
end

local function name()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end
	
	if not h.name then
		return ui.Span("")
	end
	
	local n = h.name:gsub("\r", "?", 1)
	local color
	if h.cha.is_dir then
		color = "lightblue"
	elseif h.cha.is_exec then
		color = "green"
	elseif h.cha.is_hidden then
		color = "darkgray"
	elseif h.cha.is_dummy then
		color = "red"
	elseif h.cha.is_block then
		color = "yellow"
	elseif h.cha.is_char then
		color = "yellow"
	elseif h.cha.is_fifo then
		color = "yellow"
	elseif h.cha.is_sock then
		color = "yellow"
	elseif h.cha.is_sticky then
		color = "yellow"
	else
		color = "reset"
	end
	
	return ui.Span(n):fg(color)
end

local function symlink()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end

	if not h.link_to then
		return ui.Span("")
	end
	
	local color = h.cha.is_orphan and "lightred" or "cyan"
	
	return ui.Line { ui.Span(" -> "),  ui.Span(tostring(h.link_to)):fg(color) }
end

local function nlink()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end

	if not h.cha.nlink then
		return ui.Span("")
	end

	return ui.Span(h.cha.nlink .. " ")
end

local function size()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end

	if not h.cha.len then
		return ui.Span("")
	end
	
	if h.cha.is_dir then
		return ui.Span("")
	end
	
	return ui.Span(ya.readable_size(h.cha.len))
end

local function owner()
	local h = cx.active.current.hovered
	if not h or not h.cha.uid or not h.cha.gid then
		return ui.Span("")
	end

	local user = ya.user_name(h.cha.uid) or h.cha.uid
	local user_span
	if user == "root" or user == 0 then
		user_span = ui.Span(tostring(user)):fg("lightred")
	else
		user_span = ui.Span(tostring(user))
	end
	local group = ya.group_name(h.cha.gid) or h.cha.gid
	local group_span
	if group == "root" or group == 0 then
		group_span = ui.Span(tostring(group)):fg("lightred")
	else
		group_span = ui.Span(tostring(group))
	end

	return ui.Line { user_span, ui.Span(":"), group_span }
end

local function mtime()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end

	if not h.cha.mtime then
		return ui.Span("")
	end

	return ui.Span(os.date("%Y-%m-%d %H:%M", h.cha.mtime // 1) .. " ")
end

local function isroot()
	return ya.uid() == 0 and
		ui.Line { ui.Span("ROOT"):bg("lightred"):bold(), spacer() } or
		ui.Span("")
end

return {
	setup = function()
		Status:children_remove(1, Status.LEFT) -- mode
		Status:children_remove(2, Status.LEFT) -- size
		Status:children_remove(3, Status.LEFT) -- name
		Status:children_remove(5, Status.RIGHT) -- percentage
		
		Status:children_add(isroot, 1000, Status.LEFT)
		Status:children_add(name, 2000, Status.LEFT)
		Status:children_add(symlink, 3000, Status.LEFT)
		
		Status:children_add(size, 500, Status.RIGHT)
		Status:children_add(spacer, 900, Status.RIGHT)
		Status:children_add(spacer, 1200, Status.RIGHT)
		Status:children_add(owner, 1300, Status.RIGHT)
		Status:children_add(spacer, 1400, Status.RIGHT)
		Status:children_add(mtime, 1500, Status.RIGHT)
	end,
}
