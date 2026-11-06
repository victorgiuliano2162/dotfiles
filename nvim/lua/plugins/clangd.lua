return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=never",
          "--completion-style=detailed",
          -- Permite que o clangd acesse os compiladores cruzados do PlatformIO (GCC de ESP32, AVR, ARM, etc.)
          "--query-driver=**/*gcc*,**/*g++*,**/*clang*",
        },
      },
    },
  },
}
