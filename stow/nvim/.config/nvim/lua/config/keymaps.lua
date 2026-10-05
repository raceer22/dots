-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 1. Inline math: $c$ (no gap, cursor in the middle)
vim.keymap.set("i", ".j", "$$<Left>", { desc = "Typst inline math ($|$)" })

-- 2. Display / Multiline block math:
-- $
-- c
-- $
vim.keymap.set("i", "$$", "$<CR><CR>$<Up>", { desc = "Typst block math (multiline)" })
