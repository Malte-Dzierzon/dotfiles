-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Minimal: square borders everywhere (Neovim 0.11+ global default).
-- Transparent background comes from the terminal.
vim.opt.winborder = "single"
-- Dashboard: no statusline/tabline/cmdline bar.
-- laststatus/showtabline/cmdheight are GLOBAL options: opt_local is a no-op.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("minimal_dashboard_ui", { clear = true }),
  pattern = "snacks_dashboard",
  callback = function()
    vim.o.laststatus = 0
    vim.o.showtabline = 0
    vim.o.cmdheight = 0
  end,
})
-- StatusLine/TabLine highlights: base16 re-applies a solid bg on every
-- ColorScheme event, so clearing must happen there too, not just once.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("minimal_transparent_bars", { clear = true }),
  callback = function()
    pcall(vim.api.nvim_set_hl, 0, "StatusLine", { bg = "NONE", ctermbg = "NONE" })
    pcall(vim.api.nvim_set_hl, 0, "StatusLineNC", { bg = "NONE", ctermbg = "NONE" })
    pcall(vim.api.nvim_set_hl, 0, "TabLineFill", { bg = "NONE", ctermbg = "NONE" })
    pcall(vim.api.nvim_set_hl, 0, "TabLine", { bg = "NONE", ctermbg = "NONE" })
  end,
})
-- Restore when leaving the dashboard.
vim.api.nvim_create_autocmd("BufLeave", {
  group = vim.api.nvim_create_augroup("minimal_dashboard_ui_restore", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "snacks_dashboard" then
      vim.o.laststatus = 3
      vim.o.showtabline = 2
      vim.o.cmdheight = 1
    end
  end,
})
