# auto-input-switch.nvim
This is a neovim plugin that automatically switches the input-sources (aka input-methods) of your keyboard on various occasions.<br>
これはキーボードの入力モードを様々なタイミングにおいて自動で切り替える neovim プラグインです。

For example:
- Force the input-source to be US in normal-mode.
- Restore the input-source back to Japanese on entering insert-mode, if you previously used it.
- Switch the input-source to US when neovim gains focus.
- Switch the input-source to US after exit neovim.

例えば:
- normal モード時は自動で入力モードを US（英数）にする。
- insert モードに入った際、自動で日本語入力モードに戻る。（直前に日本語入力モードを使っていた場合）
- neovim のウィンドウがフォーカスされた時に自動で入力モードを US（英数）にする。
- neovim を終了した時に自動で入力モードを US（英数）にする。


## Version History - バージョン履歴
- v2.0.0
  - Added/Removed some options.
  - オプション項目をいくつか追加/削除しました。
- v1.0.0
  - Released.
  - リリース。


## Compatibility - 互換性
NVIM v0.10.2

### OS
- macOS
- Windows
- Linux


## Prerequisites - 動作に必要なもの
With the default settings, you also need [im-select](https://github.com/daipeihust/im-select) for macOS/Windows, or [ibus](https://github.com/ibus/ibus) for Linux to be installed.<br>
デフォルト設定の場合、別途 [im-select](https://github.com/daipeihust/im-select) (macOS/Windows) または [ibus](https://github.com/ibus/ibus) (Linux) が必要になります。


## Installation - インストール
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


## Configuration - 設定
Default config:<br>
デフォルトの設定:

```lua
require('auto-input-switch').setup({
  activate = true, -- Activate the plugin? (You can toggle this with `AutoInputSwitch on|off` command at any time)
  normalize = {
    enable = true, -- Enable to normalize the input-source?
    on = { -- When to normalize (:h events)
      'InsertLeave',
      'BufLeave',
      'WinLeave',
      'FocusLost',
      'ExitPre',
    },
  },
  restore = {
    enable = true, -- Enable to restore the input-source?
    on = { -- When to restore (:h events)
      'InsertEnter',
      'FocusGained',
    },
    file_pattern = nil, -- File pattern to enable it on (nil to any file)
    -- Example:
    -- file_pattern = { '*.md', '*.txt' },

    exclude_pattern = '[-a-zA-Z0-9=~+/?!@#$%%^&_(){}%[%];:<>]',
    -- When you switch to insert-mode, the plugin checks the cursor position at the moment.
    -- And if any of the characters before & after the position match with `exclude_pattern`,
    -- the plugin cancel to restore the input-source and leave it as it is.
    -- The default value of `exclude_pattern` is alphanumeric characters with a few exceptions.
  },
  os = nil, -- 'macos', 'windows', 'linux', or nil to auto-detect
  os_settings = { -- OS-specific settings
    macos = {
      enable = true,
      cmd_get = 'im-select', -- Command to get the current input-source
      cmd_set = 'im-select %s', -- Command to set the input-source (Use `%s` as a placeholder for the input-source)
      normal_input = nil, -- Name of the input-source to normalize to when you leave insert-mode (Set nil to auto-detect)
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


## Commands - コマンド

### `AutoInputSwitch on|off`
Activate/Deactivate the whole functionality.<br>
機能全体の on/off を切り替えます。


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

