-- Minimal look: text only, transparent, square borders, no animations.
local no_icons = {
  misc = { dots = "..." },
  ft = { octo = "", gh = "", ["markdown.gh"] = "" },
  dap = {
    Stopped = { "-> ", "DiagnosticWarn", "DapStoppedLine" },
    Breakpoint = "o ",
    BreakpointCondition = "? ",
    BreakpointRejected = { "x ", "DiagnosticError" },
    LogPoint = ".> ",
  },
  diagnostics = { Error = "E ", Warn = "W ", Hint = "H ", Info = "I " },
  git = { added = "+ ", modified = "~ ", removed = "- " },
  kinds = setmetatable({}, {
    __index = function()
      return ""
    end,
  }),
}

-- Transparent background: clear bg on every colorscheme switch.
local transparent = function()
  local groups = {
    "Normal",
    "NormalFloat",
    "NormalNC",
    "SignColumn",
    "EndOfBuffer",
    "LineNr",
    "Folded",
    "NonText",
    "FloatBorder",
    "FloatTitle",
    "TelescopeNormal",
    "TelescopeBorder",
    "TelescopePromptNormal",
    "TelescopePromptBorder",
    "SnacksNormal",
    "SnacksNormalNC",
    "SnacksPicker",
    "SnacksInputNormal",
    "SnacksInputBorder",
    "NoiceCmdlinePopup",
    "NoiceCmdlinePopupBorder",
    "WhichKeyFloat",
    "LazyNormal",
    "MasonNormal",
  }
  for _, g in ipairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = g })
    if ok and hl then
      hl.bg = nil
      hl.ctermbg = nil
      pcall(vim.api.nvim_set_hl, 0, g, hl)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("minimal_transparent", { clear = true }),
  callback = transparent,
})
vim.api.nvim_create_autocmd("UIEnter", {
  group = vim.api.nvim_create_augroup("minimal_transparent_enter", { clear = true }),
  callback = function()
    vim.defer_fn(transparent, 100)
  end,
})

return {
  {
    "LazyVim/LazyVim",
    opts = {
      icons = no_icons,
      ui = { border = "single" },
    },
  },
  {
    "nvim-mini/mini.icons",
    opts = { style = "ascii" },
  },
  -- No animations, no icons in picker/explorer/notifier
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.animate = { enabled = false }
      opts.scroll = { enabled = false }
      opts.indent = opts.indent or {}
      opts.indent.animate = { enabled = false }
      opts.notifier = opts.notifier or {}
      opts.notifier.icons = { error = "E ", warn = "W ", info = "I ", debug = "D ", trace = "T " }
      opts.picker = opts.picker or {}
      opts.picker.icons = { enabled = false }
      opts.picker.prompt = "> "
      opts.explorer = opts.explorer or {}
      opts.explorer.icons = { enabled = false }
      opts.styles = opts.styles or {}
      for _, style in ipairs({ "notification", "input", "scratch", "help", "man", "lsp" }) do
        opts.styles[style] = vim.tbl_extend("force", opts.styles[style] or {}, { border = "single" })
      end
      -- Picker takes the full terminal, no floating margin look
      opts.picker.layouts = opts.picker.layouts or {}
      opts.picker.layouts.default = { layout = { width = 0, height = 0 } }
    end,
  },
  -- Startup page: vertically centered, left-aligned with margin, fully locked.
  { "nvimdev/dashboard-nvim", enabled = false },
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard.enabled = true
      opts.dashboard.width = 60
      -- Vertical center (nil = center), horizontal fixed left with margin.
      -- col is an absolute offset, so it stays put on resize.
      opts.dashboard.row = nil
      opts.dashboard.col = 3
      opts.dashboard.formats = { header = { "%s", align = "left" } }
      opts.dashboard.preset = opts.dashboard.preset or {}
      -- Title like the shell prompt: user@host, then a thin rule
      local user = vim.fn.expand("$USER")
      local host = vim.fn.hostname()
      opts.dashboard.preset.header = { user .. "@" .. host, string.rep("_", 44) }
      opts.dashboard.preset.keys = {
        { key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { key = "n", desc = "New File", action = ":ene | startinsert" },
        { key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { key = "s", desc = "Restore Session", section = "session" },
        { key = "L", desc = "Lazy", action = ":Lazy" },
        { key = "q", desc = "Quit", action = ":qa" },
      }
      opts.dashboard.sections = {
        { section = "header" },
        { section = "keys", gap = 0, padding = 1 },
      }
      -- Fully lock the dashboard window: the viewport follows the cursor,
      -- so pinning the cursor pins the view. Any cursor motion (keys,
      -- mouse, touchpad) is snapped back; wheel/scroll inputs are void.
      -- Root cause of the old failure: vim.wo[vim.fn.bufwinid(buf)]
      -- errors when FileType fires before the window exists (bufwinid=-1),
      -- so no lock keymap was ever installed. win_findbuf + pcall fix that.
      local group = vim.api.nvim_create_augroup("minimal_dashboard_lock", { clear = true })
      local anchor = { 1, 0 }
      local guard = false
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "snacks_dashboard",
        callback = function(ev)
          vim.bo[ev.buf].modifiable = false
          for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
            pcall(vim.api.nvim_set_option_value, "scrolloff", 0, { win = win })
            pcall(vim.api.nvim_set_option_value, "sidescrolloff", 0, { win = win })
          end
          -- Anchor on the first actionable line once Snacks placed the cursor.
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
              local win = vim.fn.bufwinid(ev.buf)
              if win ~= -1 then
                anchor = vim.api.nvim_win_get_cursor(win)
              end
            end
          end)
          -- Snacks recreates its CursorMoved snap inside update(), i.e.
          -- AFTER FileType fired, so clear it here on every UpdatePost.
          vim.api.nvim_create_autocmd("User", {
            group = group,
            pattern = "SnacksDashboardUpdatePost",
            callback = function()
              local buf = vim.api.nvim_get_current_buf()
              if vim.bo[buf].filetype == "snacks_dashboard" then
                pcall(vim.api.nvim_clear_autocmds, { group = "snacks_dashboard_cursor", buffer = buf })
                vim.schedule(function()
                  if vim.api.nvim_buf_is_valid(buf) then
                    local win = vim.fn.bufwinid(buf)
                    if win ~= -1 and vim.api.nvim_win_is_valid(win) then
                      anchor = vim.api.nvim_win_get_cursor(win)
                    end
                  end
                end)
              end
            end,
          })
          -- Pin: snap any cursor drift back to the anchor.
          -- Snacks installs its own CursorMoved snap (group
          -- "snacks_dashboard_cursor") that pulls the cursor onto the
          -- nearest actionable item AFTER our pin runs, which is why j
          -- still appeared to move. Clear theirs; ours is the only snap.
          pcall(vim.api.nvim_clear_autocmds, { group = "snacks_dashboard_cursor", buffer = ev.buf })
          vim.api.nvim_create_autocmd("CursorMoved", {
            group = group,
            buffer = ev.buf,
            callback = function()
              if guard then
                return
              end
              local win = vim.fn.bufwinid(ev.buf)
              if win == -1 or not vim.api.nvim_win_is_valid(win) then
                return
              end
              local cur = vim.api.nvim_win_get_cursor(win)
              if cur[1] ~= anchor[1] or cur[2] ~= anchor[2] then
                guard = true
                pcall(vim.api.nvim_win_set_cursor, win, anchor)
                guard = false
              end
            end,
          })
          -- Void viewport scroll inputs (wheel, trackpad, scroll keys).
          local noview = { "<ScrollWheelUp>", "<ScrollWheelDown>", "<ScrollWheelLeft>", "<ScrollWheelRight>" }
          for _, lhs in ipairs(noview) do
            vim.keymap.set({ "n", "v", "i" }, lhs, "<Nop>", { buffer = ev.buf })
          end
          local nomove = {
            "<Up>", "<Down>", "<Left>", "<Right>",
            "j", "k", "h", "l", "w", "W", "b", "B", "e", "E",
            "0", "$", "^", "gg", "G", "<C-d>", "<C-u>", "<C-f>", "<C-b>",
            "<C-y>", "<C-e>", "zt", "zz", "zb", "H", "M", "L",
          }
          for _, lhs in ipairs(nomove) do
            vim.keymap.set({ "n", "v" }, lhs, "<Nop>", { buffer = ev.buf })
          end
        end,
      })
    end,
  },
  -- Statusline: flat, no separators, no icons, hidden on dashboard
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_extend("force", opts.options or {}, {
        icons_enabled = false,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard" } },
      })
      opts.sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      }
    end,
  },
  -- Buffer tabs: hidden on dashboard (renders as a grey bar otherwise).
  -- No BufferLineTogglePin command exists; disable via tabline directly.
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_extend("force", opts.options or {}, {
        always_show_bufferline = false,
      })
    end,
    config = function(_, opts)
      require("bufferline").setup(opts)
      local grp = vim.api.nvim_create_augroup("minimal_bufferline_hide", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = grp,
        pattern = "snacks_dashboard",
        callback = function()
          vim.o.showtabline = 0
        end,
      })
      vim.api.nvim_create_autocmd("BufLeave", {
        group = grp,
        callback = function(ev)
          if vim.bo[ev.buf].filetype == "snacks_dashboard" then
            vim.o.showtabline = 2
          end
        end,
      })
    end,
  },
  -- Cmdline + messages: square borders, no icons
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.presets = vim.tbl_extend("force", opts.presets or {}, {
        command_palette = false,
        long_message_to_split = true,
        lsp_doc_border = true,
      })
      opts.views = opts.views or {}
      for _, view in ipairs({ "cmdline_popup", "hover", "confirm", "popup", "split" }) do
        opts.views[view] = vim.tbl_extend("force", opts.views[view] or {}, { border = { style = "single" } })
      end
    end,
  },
  -- Completion: square border, text-only kind labels
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.completion = opts.completion or {}
      opts.completion.menu = vim.tbl_extend("force", opts.completion.menu or {}, {
        border = "single",
        draw = vim.tbl_extend("force", (opts.completion.menu or {}).draw or {}, {
          columns = { { "label", "label_description", gap = 1 }, { "kind" } },
        }),
      })
      opts.completion.documentation = vim.tbl_extend("force", opts.completion.documentation or {}, {
        window = vim.tbl_extend("force", (opts.completion.documentation or {}).window or {}, { border = "single" }),
      })
    end,
  },
  -- Which-key: no icons, square border
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.icons = { mappings = false, keys = {}, breadcrumb = ">", separator = ">", group = "" }
      opts.win = vim.tbl_extend("force", opts.win or {}, { border = "single" })
    end,
  },
}
