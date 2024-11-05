--- @class blink.cmp.Source
local copilot_source = {}

function copilot_source.new(opts)
	local self = setmetatable({}, { __index = copilot_source })
	self.cache = {}
	return self
end

function copilot_source:get_completions(ctx, callback)
	local copilot_api = require("copilot.api")
	local util = require("copilot.util")
	local client = require("bcp").get_client()

	local copilot_callback = function(err, response)
		if response == nil then
			return callback({
				context = ctx,
				is_incomplete_forward = true,
				is_incomplete_backward = true,
				items = {},
			})
		end
		local items = {}
		local data = response.completions

		if data == nil then
			print("Data is nil")
			return callback({
				context = ctx,
				is_incomplete_forward = true,
				is_incomplete_backward = true,
				items = {},
			})
		end
		for _, completion in ipairs(data) do
			completion = require("bcp.format").format_item(completion)
			--- @type blink.cmp.CompletionItem
			local item = {
				kind = require("blink.cmp.types").CompletionItemKind.Lsp,
				label = completion.displayText,
				insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
				insertText = completion.text,
				description = "Copilot suggestion",
				textEdit = completion.textEdit,
				filterText = completion.filterText,
				cursor_column = completion.cursor_column,
				source_name = "copilot",
				documentation = completion.text,
				blink_render = {
					render_icon = "",
					render_name = "Copilot",
				},
			}
			table.insert(items, item)
		end

		return callback({
			context = ctx,
			is_incomplete_forward = false,
			is_incomplete_backward = false,
			items = items,
		})
	end

	copilot_api.get_completions(client, util.get_doc_params(), copilot_callback)
end

return copilot_source
