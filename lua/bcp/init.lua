local M = {}

local function find_buf_clients()
	if vim.lsp.get_clients == nil then
		return vim.tbl_filter(function(client)
			return client.name == "copilot"
		end, vim.lsp.get_active_clients())
	end

	return vim.lsp.get_clients({
		name = "copilot",
		bufnr = vim.api.nvim_get_current_buf(),
	})
end

M.get_client = function()
	local clients = find_buf_clients()

	if #clients ~= 1 then
		return
	end

	return clients[1]
end

M.setup = function(opts)
	local copilot = require("copilot")
	local blink_cmp_config = require("blink.cmp.config")
	blink_cmp_config.kind_icons["Copilot"] = ""
	M.get_client()
end

return M
