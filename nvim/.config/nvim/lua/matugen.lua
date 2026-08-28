 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1a231a',
    base01 = '#2b3b2b',
    base02 = '#263626',
    base03 = '#5f6f5f',
    base04 = '#afb6af',
    base05 = '#f2f3f2',
    base06 = '#f2f3f2',
    base07 = '#f2f3f2',
    base08 = '#fd4663',
    base09 = '#85adad',
    base0A = '#81b199',
    base0B = '#8bc18b',
    base0C = '#afd0d0',
    base0D = '#acd3ac',
    base0E = '#afd0bf',
    base0F = '#741d2b',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f3f2',          bg = '#1a231a' })
  hi('TelescopeBorder',         { fg = '#5f6f5f',             bg = '#1a231a' })
  hi('TelescopePromptNormal',   { fg = '#f2f3f2',          bg = '#1a231a' })
  hi('TelescopePromptBorder',   { fg = '#5f6f5f',             bg = '#1a231a' })
  hi('TelescopePromptPrefix',   { fg = '#8bc18b',             bg = '#1a231a' })
  hi('TelescopePromptCounter',  { fg = '#afb6af',  bg = '#1a231a' })
  hi('TelescopePromptTitle',    { fg = '#1a231a',             bg = '#8bc18b' })
  hi('TelescopePreviewTitle',   { fg = '#1a231a',             bg = '#81b199' })
  hi('TelescopeResultsTitle',   { fg = '#1a231a',             bg = '#85adad' })
  hi('TelescopeSelection',      { fg = '#f2f3f2',          bg = '#263626' })
  hi('TelescopeSelectionCaret', { fg = '#8bc18b',             bg = '#263626' })
  hi('TelescopeMatching',       { fg = '#8bc18b',             bold = true })
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
