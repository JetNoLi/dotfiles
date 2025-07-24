return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	opts = {
		map_cr = true,
		check_ts = true,
	},
	config = function(_, opts)
		require("nvim-autopairs").setup(opts)
		require("nvim-autopairs.completion.cmp").setup({ map_cr = true }) -- if using cmp
	end,
}
