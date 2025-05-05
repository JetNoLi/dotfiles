return {
	"nvzone/minty",
	event = "VeryLazy",
	cmd = { "Shades", "Huefy" },
	dependencies = {
		"nvzone/volt",
	},
	config = function()
		-- Function to check if a string is a valid color
		local function is_valid_color(col)
			-- Match hex colors: #RGB or #RRGGBB
			if col:match("^#%x%x%x$") or col:match("^#%x%x%x%x%x%x$") then
				return true
			end
			-- Match rgb() or rgba() functions
			if
				col:match("^rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)$")
				or col:match("^rgba%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*[%d%.]+%s*%)$")
			then
				return true
			end
			return false
		end

		-- Map left mouse click in normal mode
		vim.keymap.set("n", "<leader>cp", function()
			require("minty.shades").open()
		end, { silent = true, noremap = true })
	end,
}
