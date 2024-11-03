> [!WARNING]
> This plugin is in its very early stage of development, expect bugs, issues, and very bad code
# bcp.nvim
 Copilot source provider for blink.cmp

## Installation
`lazy.nvim`
```lua
{
  "nikutsuki/bcp.nvim",
  dependecies = { "zbirenbaum/copilot.lua" },

  config = function()
    require("bcp").setup()
  end,
}
```
