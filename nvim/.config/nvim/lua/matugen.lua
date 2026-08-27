 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#231a1b',
    base01 = '#3b2b2c',
    base02 = '#362627',
    base03 = '#746364',
    base04 = '#b6afaf',
    base05 = '#f3f2f2',
    base06 = '#f3f2f2',
    base07 = '#f3f2f2',
    base08 = '#b82528',
    base09 = '#c2bc70',
    base0A = '#c7916b',
    base0B = '#d5777e',
    base0C = '#d9d5a6',
    base0D = '#dea1a5',
    base0E = '#dcbaa3',
    base0F = '#3d0f10',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f3f2f2',          bg = '#231a1b' })
  hi('TelescopeBorder',         { fg = '#746364',             bg = '#231a1b' })
  hi('TelescopePromptNormal',   { fg = '#f3f2f2',          bg = '#231a1b' })
  hi('TelescopePromptBorder',   { fg = '#746364',             bg = '#231a1b' })
  hi('TelescopePromptPrefix',   { fg = '#d5777e',             bg = '#231a1b' })
  hi('TelescopePromptCounter',  { fg = '#b6afaf',  bg = '#231a1b' })
  hi('TelescopePromptTitle',    { fg = '#231a1b',             bg = '#d5777e' })
  hi('TelescopePreviewTitle',   { fg = '#231a1b',             bg = '#c7916b' })
  hi('TelescopeResultsTitle',   { fg = '#231a1b',             bg = '#c2bc70' })
  hi('TelescopeSelection',      { fg = '#f3f2f2',          bg = '#362627' })
  hi('TelescopeSelectionCaret', { fg = '#d5777e',             bg = '#362627' })
  hi('TelescopeMatching',       { fg = '#d5777e',             bold = true })
end

 -- Register a signal handler for SIGUSR1 (matugen updates)
 local signal = vim.uv.new_signal()
 signal:start(
   'sigusr1',
   vim.schedule_wrap(function()
     package.loaded['matugen'] = nil
     require('matugen').setup()
   end)
 )

 return M
