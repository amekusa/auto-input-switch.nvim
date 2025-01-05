# auto-input-switch.nvim
This is a neovim plugin that automatically switches the input-sources (aka input-methods) of your keyboard on various occasions.
これはキーボードの入力モードを様々なタイミングで自動で切り替える neovim プラグインです。

For example:
- Force the input-source to be US in normal-mode.
- Restore the input-source back to Japanese on enter insert-mode, if you were previously using it.
- Switch the input-source to US when neovim gain focus.

例えば:
- normal モード時は自動で入力モードを US（英数）にする。
- insert モードに入った際、自動で日本語入力モードに戻る。（直前に日本語入力モードを使っていた場合）
- neovim のウィンドウがフォーカスされた時に自動で入力モードを US（英数）にする。


## Compatibility - 互換性
NVIM v0.10.2

### OS
- macOS
- Windows
- Linux


## Prerequisites - 動作に必要なもの
On macOS or Windows, you may also need [im-select](https://github.com/daipeihust/im-select) to be installed.
macOS か Windows の場合、別途 [im-select](https://github.com/daipeihust/im-select) が必要になります。


## Installation - インストール
```lua
require('lazy').setup({
	{
		'amekusa/auto-input-switch',
		config = function()
			require('auto-input-switch').setup({
				-- your options
			})
		end
	},
})
```


## Configuration - 設定
Default config:
デフォルトの設定:
```lua
require('auto-input-switch').setup({
	activate = true, -- Activate the plugin? (You can toggle this with `AutoInputSwitch on|off` command)
	features = {
		normalize_on_focus            = true, -- Switch the input-source to `normal_input` when neovim gain focus
		normalize_on_leave_insertmode = true, -- Switch the input-source to `normal_input` on leave insert-mode
		restore_on_enter_insertmode   = true, -- Restore the input-source to the state before the last "normalize"
	},
	os = nil, -- 'macos', 'windows', or 'linux' (nil to auto-detect)
	os_settings = {
		macos = {
			enable = true,
			cmd_get = 'im-select', -- Command to get the current input-source
			cmd_set = 'im-select %s', -- Command to set the input-source (use `%s` as a placeholder)
			normal_input = nil, -- Name of the input-source you want to use in normal-mode (nil to auto-detect)
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

