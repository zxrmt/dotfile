
return {
	"neovim/nvim-lspconfig",

	config = function()
		require'lspconfig'.clangd.setup{}

		require'lspconfig'.rust_analyzer.setup {
			settings = {
				['rust-analyzer'] = {
					check = {
						command = "clippy";
					},
					diagnostics = {
						enable = true;
					}
				}
			}
		}


	end,
}
