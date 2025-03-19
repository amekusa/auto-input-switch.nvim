# auto-input-switch.nvim
![GitHub Tag](https://img.shields.io/github/v/tag/amekusa/auto-input-switch.nvim?label=stable&link=https%3A%2F%2Fgithub.com%2Famekusa%2Fauto-input-switch.nvim%2Ftags)

**English** / [日本語](README.ja.md)

This is a Neovim plugin that automatically switches the input sources (aka input methods) of your keyboard on various occasions,
improving your writing experience in non-English languages.

For example, it can:

- Force the input source to be US in Normal-mode.
- Detect the language of the characters near the cursor, and switch the input source to the one for the language.
- Switch the input source to Japanese on entering Insert-mode, if you previously used it.
- Switch the input source to US when Neovim gains focus.
- Switch the input source to US after exiting Neovim.


## Version History

```
v3.3.0 - Now `os_settings.*.normal_input` supports a table value like this:
           normal_input = { 'com.apple.keylayout.ABC', 'eisu' },
         The 1st string is the name of the input source, which should match with the output of `cmd_get`.
         The 2nd string is what is actually passed to `cmd_set`.

       - Each entry of `os_settings.*.lang_inputs` also supports a table just like `normal_input`.
       - New option `prefix`.
       - New option `popup.zindex`.
       - Fixed the issue that popup may interfere opening other floating windows.
       - Fixed the errors on `AutoInputSwitchRestore` and `AutoInputSwitchMatch` commands.

v3.2.0 - New feature "Popup".
v3.1.0 - New option `match.lines`.
v3.0.0 - New feature "Match".
v2.2.0 - Support `async` option.
v2.0.0 - Added/Removed some options.
v1.0.0 - Released.
```


## Compatibility 
NVIM v0.10.2

### OS
- macOS
- Windows
- Linux


## Prerequisites
With the default settings, you also need [im-select](https://github.com/daipeihust/im-select) for macOS/Windows, or [ibus](https://github.com/ibus/ibus) for Linux to be installed.
Alternatively, [macism](https://github.com/laishulu/macism) can be a better choice over im-select for macOS.


## Installation
```lua
require('lazy').setup({

  {
    'amekusa/auto-input-switch.nvim',
    config = function()
      require('auto-input-switch').setup({
        -- your options
      })
    end
  },

})
```


## Configuration
Default options:

```lua
require('auto-input-switch').setup({
  activate = true, -- Activate the plugin?
  -- You can toggle this with `AutoInputSwitch on|off` command at any time.

  async = false, -- Run `cmd_get` & `cmd_set` asynchronously?
  -- false: Runs synchronously. (Recommended)
  --        You may encounter subtle lags if you switch between Insert-mode and Normal-mode very rapidly.
  --  true: Runs asynchronously.
  --        No lags, but less reliable than synchronous.

  prefix = 'AutoInputSwitch', -- Prefix of the command names

  popup = {
    -- When the plugin changed the input source, it can indicate the language of the current input source with a popup.

    enable = true, -- Show popups?
    duration = 1500, -- How long does a popup remain visible? (ms)
    pad = true, -- Whether to add leading & trailing spaces
    hl_group = 'PmenuSel', -- Highlight group

    -- Popup window settings (:h nvim_open_win())
    border = 'none', -- Style of the window border
    zindex = 50, -- Rendering priority
    row = 1, -- Horizontal offset
    col = 0, -- Vertical offset
    relative = 'cursor', -- The offsets are relative to: editor/win/cursor/mouse
    anchor = 'NW', -- Which corner is a popup window aligned to?
    -- 'NW' : Northwest
    -- 'NE' : Northeast
    -- 'SW' : Southwest
    -- 'SE' : Southeast
  },

  normalize = {
    -- In Normal-mode or Visual-mode, you always want the input source to be alphanumeric, regardless of your keyboard's locale.
    -- The plugin can automatically switch the input source to the alphanumeric one when you escape from Insert-mode to Normal-mode.
    -- We call this feature "Normalize".

    enable = true, -- Enable Normalize?
    on = { -- Events to trigger Normalize (:h events)
      'InsertLeave',
      'BufLeave',
      'WinLeave',
      'FocusLost',
      'ExitPre',
    },
    file_pattern = nil, -- File pattern to enable Normalize (nil to any file)
    -- Example:
    -- file_pattern = { '*.md', '*.txt' },

    popup = 'ABC', -- Popup text to show when normalize (nil to disable)
  },

  restore = {
    -- When "Normalize" is about to happen, the plugin saves the state of the input source at the moment.
    -- And the next time you enter Insert-mode, it can automatically restore the saved state.
    -- We call this feature "Restore".

    enable = true, -- Enable Restore?
    on = { -- Events to trigger Restore (:h events)
      'InsertEnter',
      'FocusGained',
    },
    file_pattern = nil, -- File pattern to enable Restore (nil to any file)
    -- Example:
    -- file_pattern = { '*.md', '*.txt' },

    exclude_pattern = '[-a-zA-Z0-9=~+/?!@#$%%^&_(){}%[%];:<>]',
    -- When you switch to Insert-mode, the plugin checks the cursor position at the moment.
    -- And if any of the characters before & after the position match with `exclude_pattern`,
    -- the plugin cancel to restore the input source and leave it as it is.
    -- The default value of `exclude_pattern` is alphanumeric characters with a few exceptions.
    -- Set nil to disable this feature.
  },

  match = {
    -- When you enter Insert-mode, the plugin can detect the language of the characters adjacent to the cursor at the moment.
    -- Then, it can automatically switch the input source to the one that matches the detected language.
    -- We call this feature "Match".
    -- If you enable this feature, we recommend to set `restore.enable` to false.
    -- This feature is disabled by default.

    enable = false, -- Enable Match?
    on = { -- Events to trigger Match (:h events)
      'InsertEnter',
      'FocusGained',
    },
    file_pattern = nil, -- File pattern to enable Match (nil to any file)
    -- Example:
    -- file_pattern = { '*.md', '*.txt' },

    languages = {
      -- Languages to match with the characters. Set `enable` to true for the ones you want to use.
      -- `pattern` must be a valid regex string. Use the unicode ranges corresponding to the language.
      -- You can also add your own languages.
      -- If you do, do not forget to add the input sources for them as well, to `os_settings[Your OS].lang_inputs`.
      Ru = { enable = false, priority = 0, pattern = '[\\u0400-\\u04ff]' },
      Ja = { enable = false, priority = 0, pattern = '[\\u3000-\\u30ff\\uff00-\\uffef\\u4e00-\\u9fff]' },
      Zh = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u4e00-\\u9fff\\u3400-\\u4dbf\\u3100-\\u312f]' },
      Ko = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u1100-\\u11ff\\u3130-\\u318f\\uac00-\\ud7af]' },
    },

    lines = {
      -- If the current line is empty or has only whitespace characters,
      -- the plugin can also checks the lines above/below the current line that if they have any characters match `languages`.
      above = 2, -- How meany lines above the current line to check
      below = 1, -- How meany lines below the current line to check
    },
  },

  os = nil, -- 'macos', 'windows', 'linux', or nil to auto-detect
  os_settings = { -- OS-specific settings
    macos = {
      enable = true,
      cmd_get = 'im-select', -- Command to get the current input source
      cmd_set = 'im-select %s', -- Command to set the input source (Use `%s` as a placeholder for the input source)
      normal_input = nil, -- Name of the input source for Normalize (Set nil to auto-detect)
      -- Examples:
      -- normal_input = 'com.apple.keylayout.ABC',
      -- normal_input = 'com.apple.keylayout.US',
      -- normal_input = 'com.apple.keylayout.USExtended',

      -- You can also use a table like this:
      -- normal_input = { 'com.apple.keylayout.ABC', 'eisu' },
      --   The 1st string is the name of the input source, which should match with the output of `cmd_get`.
      --   The 2nd string is what is actually passed to `cmd_set`.

      lang_inputs = {
        -- The input sources corresponding to `match.languages` for each.
        -- You can also use a table for each entry just like `normal_input`.
        Ru = 'com.apple.keylayout.Russian',
        Ja = 'com.apple.inputmethod.Kotoeri.Japanese',
        Zh = 'com.apple.inputmethod.SCIM.ITABC',
        Ko = 'com.apple.inputmethod.Korean.2SetKorean',
      },
    },
    windows = {
      enable = true,
      cmd_get = 'im-select.exe',
      cmd_set = 'im-select.exe %s',
      normal_input = nil,
      lang_inputs = {},
    },
    linux = {
      enable = true,
      cmd_get = 'ibus engine',
      cmd_set = 'ibus engine %s',
      normal_input = nil,
      lang_inputs = {},
    },
  },
})
```


## Configuration Examples

```lua
-- Enable to match Japanese, Chinese, and Korean languages
require('auto-input-switch').setup({
  restore = { enable = false },
  match = {
    enable = true,
    languages = {
      Ja = { enable = true, priority = 1 },
      Zh = { enable = true, priority = 0 },
      Ko = { enable = true },
    }
  }
})
```

Since Japanese and Chinese partially share the same unicode ranges,
it is important to specify `priority` numbers for each language.


## Commands

`:AutoInputSwitch on|off`

Activate/Deactivate the whole functionality.


`:AutoInputSwitchNormalize`

Manually normalize the input source.


`:AutoInputSwitchRestore`

Manually restore the input source.


`:AutoInputSwitchMatch`

Manually match the input source.


## License
Copyright (c) 2025 Satoshi Soma <noreply@amekusa.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

