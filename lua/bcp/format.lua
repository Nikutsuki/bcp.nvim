local pattern = require("bcp.pattern")
local format = {}

local label_text = function(text)
	local text_len = vim.fn.strchars(text)
	local shorten = function(str)
		local short_prefix = vim.fn.strcharpart(str, 0, 20)
		local short_suffix = vim.fn.strcharpart(str, text_len - 15, text_len)
		local delimiter = " ... "
		return short_prefix .. delimiter .. short_suffix
	end
	text = text:gsub("^%s*", "")
	return text_len > 40 and shorten(text) or text
end

format.get_indent_string = function(text)
	return string.match(text, "^%s*")
end

format.get_newline_char = function(text)
	if string.find(text, "\n") ~= nil then
		return "\n"
	else
		return nil
	end
end

-- deindents all lines and sets relative indent level to indent_level spaces
format.deindent = function(text, user_indent)
	local indent = string.match(text, "^%s*")
	if not indent then
		return text
	end

	local deindented =
		string.gsub(string.gsub(string.gsub(text, "^" .. indent, ""), "\n" .. indent, "\n"), "[\r|\n]$", "")

	if #indent == 0 or not user_indent or user_indent == indent then
		return deindented
	end

	local lines = format.split(deindented, "\n")
	for k, v in ipairs(lines) do
		lines[k] = string.gsub(v, "^" .. indent, user_indent)
	end
	return table.concat(lines, "\n")
end

format.add_indent = function(text, user_indent, indent_level)
	if not indent_level or indent_level == 0 then
		return text
	end

	local lines = format.split(text, "\n")
	local indent_str = string.rep(user_indent, indent_level)
	for k, v in ipairs(lines) do
		lines[k] = indent_str .. v
	end
	return table.concat(lines, "\n")
end

format.remove_leading_whitespace = function(text)
	return text:gsub("^%s*", "")
end

format.split = function(inputstr, sep)
	sep = sep or inputstr:find("\r") and "\r" or "\n"
	if sep == nil then
		sep = "\n"
	end
	if not string.find(inputstr, "[\r|\n]") then
		return { inputstr }
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

format.get_indent_offset = function(text)
	return #text - #format.remove_leading_whitespace(text)
end

format.to_multi_line = function(item, ctx)
	-- get indent on line before cursor
	local indent_offset = format.get_indent_offset(ctx.cursor_before_line)
	local user_indent = string.match(ctx.cursor_before_line, "^%s")

	-- if there is no indent on line before cursor, detect via expandtab settings
	-- have to do this to correcly force compliance with shiftwidth for multilines
	if user_indent == nil then
		user_indent = vim.bo.expandtab and " " or "\t"
	end

	-- if tabs , indent offset is the same as indent level
	local indent_level = indent_offset
	-- if spaces, force compliance with shiftwidth
	if user_indent == " " then
		user_indent = string.rep(" ", vim.o.shiftwidth)
		indent_level = math.floor(indent_offset / vim.o.shiftwidth)
	end

	-- deindent everything and set all relative indents vim.o.shiftwidth spaces or one tab char
	local preview = format.deindent(item.text, user_indent)
	local text = preview

	-- add indent equal to whitespace before cursor to every line
	if user_indent ~= nil then
		text = format.add_indent(preview, user_indent, indent_level)
	end

	-- get abbreviated label
	local label = label_text(text)
	local splitText = format.split(text)
	local offset = {
		start = {
			line = item.range.start.line,
			character = item.range.start.character,
		},
		["end"] = {
			line = item.range["end"].line,
			character = #splitText[1],
		},
	}
	return {
		preview = preview,
		label = label,
		text = text,
		insert = offset,
		replace = offset,
	}
end

local function handle_suffix(text, suffix)
	local tbl = format.split(text)
	tbl[1] = pattern.set_suffix(tbl[1], suffix)
	local res = ""
	for i, v in ipairs(tbl) do
		res = res .. v
		if i < #tbl then
			res = res .. "\n"
		end
	end
	return res
end

local function get_text_after_cursor()
	local line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

	return string.sub(line, cursor_col + 1)
end

local function get_text_before_cursor()
	local line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

	return string.sub(line, 1, cursor_col)
end

local ctx = {
	cursor_after_line = "",
	cursor_before_line = "",
}

format.format_item = function(item)
	ctx.cursor_after_line = get_text_after_cursor()
	ctx.cursor_before_line = get_text_before_cursor()

	item.text = handle_suffix(item.text, ctx)
	item.displayText = handle_suffix(item.displayText, ctx)

	local multi_line = format.to_multi_line(item, ctx)

	return {
		displayText = multi_line.label,
		text = multi_line.text,
		filterText = multi_line.newText,
		textEdit = {
			newText = multi_line.text,
			insert = multi_line.insert,
			replace = multi_line.replace,
		},
		cursor_column = vim.api.nvim_win_get_cursor(0)[2],
	}
end

return format
