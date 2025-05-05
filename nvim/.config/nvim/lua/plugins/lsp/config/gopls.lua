local config = {
	analyses = {
		unusedparams = true,
	},
	staticcheck = true,
	gofumpt = true,
	goimports = true,
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
