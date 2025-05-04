return {
	"koron/iferr",
	ft = { "go", "templ" },
	build = "go install github.com/koron/iferr@latest",
	cmd = "IfErr",
	config = function()
		-- load the ftplugin so that :IfErr is defined
		vim.cmd([[runtime vim/ftplugin/go/iferr.vim]])
	end,
}
