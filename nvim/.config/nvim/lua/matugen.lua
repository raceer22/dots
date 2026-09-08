 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1a1f23',
    base01 = '#2b343b',
    base02 = '#262f36',
    base03 = '#616a71',
    base04 = '#afb3b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#967fb3',
    base0A = '#7f82b3',
    base0B = '#8ba9c1',
    base0C = '#bdafd0',
    base0D = '#acc1d3',
    base0E = '#afb1d0',
    base0F = '#cdcfe4',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#1a1f23' })
  hi('TelescopeBorder',         { fg = '#616a71',             bg = '#1a1f23' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#1a1f23' })
  hi('TelescopePromptBorder',   { fg = '#616a71',             bg = '#1a1f23' })
  hi('TelescopePromptPrefix',   { fg = '#8ba9c1',             bg = '#1a1f23' })
  hi('TelescopePromptCounter',  { fg = '#afb3b6',  bg = '#1a1f23' })
  hi('TelescopePromptTitle',    { fg = '#1a1f23',             bg = '#8ba9c1' })
  hi('TelescopePreviewTitle',   { fg = '#1a1f23',             bg = '#7f82b3' })
  hi('TelescopeResultsTitle',   { fg = '#1a1f23',             bg = '#967fb3' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#262f36' })
  hi('TelescopeSelectionCaret', { fg = '#8ba9c1',             bg = '#262f36' })
  hi('TelescopeMatching',       { fg = '#8ba9c1',             bold = true })
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
