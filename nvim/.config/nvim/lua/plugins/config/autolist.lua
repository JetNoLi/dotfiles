return {
	"gaoDean/autolist.nvim",
	-- lazy-load when opening or creating text-like files
	-- event = { "BufReadPre", "BufNewFile" },
	ft = { "markdown", "text", "tex", "plaintex", "norg" },
	config = function()
		-- use all the defaults, plus sensible keymaps:
		require("autolist").setup()

		-- Tab to indent (AutolistTab), Shift-Tab to dedent (AutolistShiftTab) :contentReference[oaicite:0]{index=0}
		vim.keymap.set("i", "<Tab>", "<cmd>AutolistTab<CR>", { buffer = true })
		vim.keymap.set("i", "<S-Tab>", "<cmd>AutolistShiftTab<CR>", { buffer = true })

		-- <CR> in insert: continue list, or remove empty bullet :contentReference[oaicite:1]{index=1}
		vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<CR>", { buffer = true })

		-- In normal mode: `o`/`O` continue lists, `<CR>` toggles checkbox then newline :contentReference[oaicite:2]{index=2}
		vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<CR>", { buffer = true })
		vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<CR>", { buffer = true })
		vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<CR><CR>", { buffer = true })
	end,
}
