return {
  "folke/neodev.nvim",
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  {
    "nvim-telescope/telescope.nvim", tag = '0.1.8',
    dependencies = { {'nvim-lua/plenary.nvim'} }
  },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000,
    config = function()
        vim.cmd.colorscheme "catppuccin"
    end
  },
  {'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'},
  {"williamboman/mason.nvim",},
  "williamboman/mason-lspconfig.nvim",
  {"L3MON4D3/LuaSnip"},
  {'VonHeikemen/lsp-zero.nvim'},
  {'neovim/nvim-lspconfig'},
  {'hrsh7th/cmp-nvim-lsp'},
  {'hrsh7th/nvim-cmp'},
  {'saadparwaiz1/cmp_luasnip'},
  {
    'stevearc/aerial.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = {
       "nvim-treesitter/nvim-treesitter",
       "nvim-tree/nvim-web-devicons"
    },
  },
  {'simrat39/symbols-outline.nvim'},
  {'mhinz/vim-startify'},
  {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  {'tpope/vim-fugitive'},
  {'lewis6991/gitsigns.nvim'},
}
