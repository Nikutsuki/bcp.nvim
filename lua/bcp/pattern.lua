local pattern = {}

local ch_pairs = {
	["("] = "%)",
	["["] = "%]",
	["{"] = "%}",
	[")"] = "%(",
	["]"] = "%[",
	["}"] = "%{",
}

local fmt_char = {
	["("] = "%(",
	["["] = "%[",
	["{"] = "%{",
	[")"] = "%)",
	["]"] = "%]",
	["}"] = "%}",
}

-- check if text has pair for char c
local function text_has_pair(text, c)
	if not text or not c then
		return false
	end
	return text:find(ch_pairs[c]) ~= nil
end

-- check if text has char c
local function text_has_char(text, c)
	if not text or not c then
		return false
	end
	c = fmt_char[c] or c
	return text:find(c) ~= nil
end

function pattern.set_suffix(text, line_suffix)
	for i = 1, #line_suffix do
		local c = line_suffix:sub(i, i)
		if ch_pairs[c] and text_has_pair(text, c) and not text_has_char(text, c) then
			text = text .. c
		end
	end
	return text
end

return pattern
