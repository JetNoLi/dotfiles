return {
	-- lspconfig's default also attaches htmx to JS/TS, Vue and Svelte buffers,
	-- where it never answers hover, so K waits on it and shows nothing.
	filetypes = { "html", "templ" },
}
