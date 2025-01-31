# auto-input-switch.nvim

**English** / [日本語](README.ja.md)

This is a Neovim plugin that automatically switches the input sources (aka input methods) of your keyboard on various occasions,
improving your writing experience in non-English languages.

For example, it can:

- Force the input source to be US in Normal-mode.
- Switch the input source to Japanese on entering Insert-mode, if you previously used it.
- Switch the input source to US when Neovim gains focus.
- Switch the input source to US after exiting Neovim.


## Version History
- v2.2.0
  - Support `async` option.
- v2.0.0
  - Added/Removed some options.
- v1.0.0
  - Released.


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

  normalize = {
    -- In Normal-mode or Visual-mode, you always want the input source to be alphanumeric, regardless of your keyboard's locale.
    -- the plugin can automatically switch the input source to the alphanumeric one when you escape from Insert-mode to Normal-mode.
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
    },
    windows = {
      enable = true,
      cmd_get = 'im-select.exe',
      cmd_set = 'im-select.exe %s',
      normal_input = nil, -- auto
    },
    linux = {
      enable = true,
      cmd_get = 'ibus engine',
      cmd_set = 'ibus engine %s',
      normal_input = nil, -- auto
    },
  },
})
```


## Commands

`:AutoInputSwitch on|off`

Activate/Deactivate the whole functionality.


`:AutoInputSwitchNormalize`

Manually normalize the input source.


`:AutoInputSwitchRestore`

Manually restore the input source.


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

