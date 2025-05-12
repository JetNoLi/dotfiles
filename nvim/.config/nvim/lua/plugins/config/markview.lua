return {
	"OXY2DEV/markview.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons", -- optional, for file icons
	},
	config = function()
		require("markview").setup({
			markdown = {
				block_quotes = {
					enable = true,
				},
				checkboxes = {
					symbols = {
						unchecked = "☐",
						checked = "☑",
						indeterminate = "☐",
					},
				},
				headings = {

					enable = true,
				},
			},
			-- Additional configuration can be added here
		})

		local cb = require("markview.extras.checkboxes")
		cb.setup()

		-- vim.keymap.set("n", "<leader>cb", ":Checkbox interactive<CR>", { desc = "Toggle Markdown Checkbox" })
		-- vim.keymap.set("n", "<leader>cb", function()
		-- local interactive = cb.interactive

		-- if interactive and interactive.__close then
		-- If interactive mode is active, exit it
		-- interactive.__close()
		-- else
		-- If not in interactive mode, enter it
		-- vim.cmd("Checkbox interactive")
		-- end
		-- end, { desc = "Toggle Markdown Checkbox" })
		--
		-- vim.keymap.set("n", "<leader><leader>", function()
		-- require("markview.extras.checkboxes").change()
		-- end, { desc = "Toggle Markdown Checkbox" })
	end,
}
