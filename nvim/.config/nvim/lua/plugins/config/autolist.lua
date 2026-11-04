local filetypes = { "markdown", "text", "tex", "plaintex", "norg" }

-- Buffer-local, so they're set on every list buffer, not just the first one.
local function set_keymaps(buf)
	local opts = { buffer = buf }

	-- Tab to indent, Shift-Tab to dedent
	vim.keymap.set("i", "<Tab>", "<cmd>AutolistTab<CR>", opts)
	vim.keymap.set("i", "<S-Tab>", "<cmd>AutolistShiftTab<CR>", opts)

	-- <CR> in insert: continue list, or remove empty bullet
	vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<CR>", opts)

	-- In normal mode: `o`/`O` continue lists, `<CR>` toggles checkbox then newline
	vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<CR>", opts)
	vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<CR>", opts)
	vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<CR><CR>", opts)
end

return {
	"gaoDean/autolist.nvim",
	ft = filetypes,
	config = function()
		require("autolist").setup()

		vim.api.nvim_create_autocmd("FileType", {
			pattern = filetypes,
			callback = function(args)
				set_keymaps(args.buf)
			end,
		})

		-- The buffer that triggered the lazy load already had its FileType event.
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.tbl_contains(filetypes, vim.bo[buf].filetype) then
				set_keymaps(buf)
			end
		end
	end,
}
