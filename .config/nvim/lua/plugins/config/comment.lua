-- Comment Like VS
local config = {
	"numToStr/Comment.nvim",
	config = function()
		require("Comment").setup()
	end,
	keys = {
		{ "gc", mode = { "n", "v" }, desc = "Toggle comment" },
		{
			"<D-/>",
			mode = { "n", "v" },
			function()
				require("Comment.api").toggle.linewise.current()
			end,
			desc = "Toggle comment macOS style",
		},
	},
}

return config
