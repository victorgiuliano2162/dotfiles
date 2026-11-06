-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add local map = vim.keymap.set

local map = vim.keymap.set

-- PlatformIO Mappings
map("n", "<leader>pb", "<cmd>terminal pio run<CR>", { desc = "PlatformIO: Build (Compilar)" })
map("n", "<leader>pu", "<cmd>terminal pio run -t upload<CR>", { desc = "PlatformIO: Upload (Gravar)" })
map("n", "<leader>pm", "<cmd>terminal pio device monitor<CR>", { desc = "PlatformIO: Monitor Serial" })
map("n", "<leader>pc", "<cmd>terminal pio run -t compiledb<CR>", { desc = "PlatformIO: Gerar compile_commands.json" })
