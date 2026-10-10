-- Noctalia/matugen colorscheme: base16 palette + Telescope/mini.pick highlights,
-- live-reloaded via SIGUSR1 (send `pkill -USR1 nvim` after matugen regenerates).
return {
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("matugen").setup()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "base16-noctalia" },
  },
}
