return {
	"nvzone/minty",
	event = "VeryLazy",
	cmd = { "Shades", "Huefy" },
	dependencies = {
		"nvzone/volt",
	},
	config = function()
		-- Function to check if a string is a valid color
		-- Map left mouse click in normal mode
		vim.keymap.set("n", "<leader>cp", function()
			require("minty.shades").open()
		end, { silent = true, noremap = true })
	end,
}
