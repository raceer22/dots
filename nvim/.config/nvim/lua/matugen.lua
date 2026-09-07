 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1a1f23',
    base01 = '#2b343b',
    base02 = '#262f36',
    base03 = '#606a70',
    base04 = '#afb3b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#cbc1d9',
    base0A = '#c1c3d9',
    base0B = '#bed0dc',
    base0C = '#bcafd0',
    base0D = '#acc3d2',
    base0E = '#afb1d0',
    base0F = '#cdcfe4',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#1a1f23' })
  hi('TelescopeBorder',         { fg = '#606a70',             bg = '#1a1f23' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#1a1f23' })
  hi('TelescopePromptBorder',   { fg = '#606a70',             bg = '#1a1f23' })
  hi('TelescopePromptPrefix',   { fg = '#bed0dc',             bg = '#1a1f23' })
  hi('TelescopePromptCounter',  { fg = '#afb3b6',  bg = '#1a1f23' })
  hi('TelescopePromptTitle',    { fg = '#1a1f23',             bg = '#bed0dc' })
  hi('TelescopePreviewTitle',   { fg = '#1a1f23',             bg = '#c1c3d9' })
  hi('TelescopeResultsTitle',   { fg = '#1a1f23',             bg = '#cbc1d9' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#262f36' })
  hi('TelescopeSelectionCaret', { fg = '#bed0dc',             bg = '#262f36' })
  hi('TelescopeMatching',       { fg = '#bed0dc',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
