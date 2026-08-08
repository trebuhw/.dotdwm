return {
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      options = {
        parsers = {
          css = true, -- obejmuje hex, rgb, hsl itd.
          tailwind = { enable = false },
        },
        display = {
          mode = "background", -- zamiast virtualtext
        },
      },
    },
  },
}
