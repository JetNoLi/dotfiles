local config = {}

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.js", "*.ts", "*.css", "*.html", "*.json", "*.yaml", "*.md", "*.tsx" },
	callback = function()
		vim.lsp.buf.format({ timeout_ms = 2000 })
	end,
})

return config
