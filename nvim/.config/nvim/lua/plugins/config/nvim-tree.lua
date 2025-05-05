vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

vim.keymap.set("n", "<leader>fe", "<CMD>NvimTreeToggle<CR>", { desc = "Toggle Nvim-Tree" })

return {
	"nvim-tree/nvim-tree.lua",
	dependencies = {
		"nvim-web-devicons",
	},
	opts = {
		hijack_netrw = false, -- Prevent nvim-tree from overriding netrw
		update_focused_file = {
			enable = true,
			update_cwd = true,
		},
		view = {
			width = 30,
			side = "left",
		},
	},
	cmd = { "NvimTreeToggle", "NvimTreeOpen" },
}
