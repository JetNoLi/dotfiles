local config = {
	analyses = {
		unusedparams = true,
		unreachable = true,
		nilness = true,
		shadow = true,
	},
	staticcheck = true, -- Enables extra checks (like vet + more)	gofumpt = true,
	-- goimports = true,
	settings = {
		gopls = {
			rename = true,
			gofumpt = true,
		},
	},

	on_attach = function(_, bufnr)
		-- Organize imports before saving
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.code_action({
					context = { only = { "source.organizeImports" } },
					apply = true,
				})
				-- Then format (gofumpt/gofmt)
				vim.lsp.buf.format({ async = false })
			end,
		})
	end,
}

return config
