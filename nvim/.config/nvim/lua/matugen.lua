 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1c1e1a',
    base01 = '#252722',
    base02 = '#2f322c',
    base03 = '#666961',
    base04 = '#a2b08d',
    base05 = '#f4f6eb',
    base06 = '#f4f6eb',
    base07 = '#f4f6eb',
    base08 = '#ce7a71',
    base09 = '#6e857b',
    base0A = '#948e74',
    base0B = '#a2b08d',
    base0C = '#96e9c5',
    base0D = '#c8e996',
    base0E = '#e9d996',
    base0F = '#f4e9be',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f4f6eb',          bg = '#1c1e1a' })
  hi('TelescopeBorder',         { fg = '#666961',             bg = '#1c1e1a' })
  hi('TelescopePromptNormal',   { fg = '#f4f6eb',          bg = '#1c1e1a' })
  hi('TelescopePromptBorder',   { fg = '#666961',             bg = '#1c1e1a' })
  hi('TelescopePromptPrefix',   { fg = '#a2b08d',             bg = '#1c1e1a' })
  hi('TelescopePromptCounter',  { fg = '#a2b08d',  bg = '#1c1e1a' })
  hi('TelescopePromptTitle',    { fg = '#1c1e1a',             bg = '#a2b08d' })
  hi('TelescopePreviewTitle',   { fg = '#1c1e1a',             bg = '#948e74' })
  hi('TelescopeResultsTitle',   { fg = '#1c1e1a',             bg = '#6e857b' })
  hi('TelescopeSelection',      { fg = '#f4f6eb',          bg = '#2f322c' })
  hi('TelescopeSelectionCaret', { fg = '#a2b08d',             bg = '#2f322c' })
  hi('TelescopeMatching',       { fg = '#a2b08d',             bold = true })
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
