# auto-input-switch.nvim

[English](README.md) / **日本語**

これはキーボードの入力モードを様々なタイミングにおいて自動で切り替える Neovim プラグインです。
英語以外の言語によるライティング・エクスペリエンスを向上させます。

例えば、以下のようなことが実現可能です:

- Normal モード時は自動で入力モードを US（英数）にする。
- Insert モードに入った際、自動で日本語入力モードに戻る。（直前に日本語入力モードを使っていた場合）
- Neovim のウィンドウがフォーカスされた時に自動で入力モードを US（英数）にする。
- Neovim を終了した時に自動で入力モードを US（英数）にする。


## バージョン履歴
- v2.0.0
  - オプション項目をいくつか追加/削除しました。
- v1.0.0
  - リリース。


## 互換性
NVIM v0.10.2

### OS
- macOS
- Windows
- Linux


## 動作に必要なもの
デフォルト設定の場合、別途 [im-select](https://github.com/daipeihust/im-select) (macOS/Windows) または [ibus](https://github.com/ibus/ibus) (Linux) が必要になります。
あるいは macOS の場合、[macism](https://github.com/laishulu/macism) の方が im-select よりも良いかもしれません。


## インストール
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


## 設定
デフォルトの設定:

```lua
require('auto-input-switch').setup({
  activate = true, -- 本プラグインの機能を有効にするか否か。
  -- このフラグは `AutoInputSwitch on|off` コマンドでいつでも切り替え可能です。

  async = false, -- `cmd_get` & `cmd_set` の実行を非同期で行うか否か。
  -- false: 同期実行。(推奨)
  --        Insert モードと Normal モード間の切り替えを素早く繰り返した際などに僅かなラグが発生する場合があります。
  --  true: 非同期実行。
  --        ラグは発生しませんが、同期実行よりも信頼性に劣ります。

  normalize = {
    -- Normal モードか Visual モードにおいては、使用するキーボードの言語に関わらず、入力モードは常に半角英数であるべきです。
    -- 本プラグインは、ユーザーが Insert モードから Normal モードに変更する際に、自動で入力モードを半角英数に切り替えることができます。
    -- この機能を "Normalize" と呼称します。

    enable = true, -- Normalize を有効にするか否か。
    on = { -- Normalize のトリガーとなるイベント。(:h events)
      'InsertLeave',
      'BufLeave',
      'WinLeave',
      'FocusLost',
      'ExitPre',
    },
    file_pattern = nil, -- Normalize が有効となるファイル名のパターン。 (nil は全ファイル)
    -- 例:
    -- file_pattern = { '*.md', '*.txt' },
  },

  restore = {
    -- "Normalize" が実行される際、本プラグインによって直前の入力モードが記憶されます。
    -- そしてユーザーが次に Insert モードに移行した瞬間、記憶していた入力モードを自動的に復元することができます。
    -- この機能を "Restore" と呼称します。

    enable = true, -- Restore を有効にするか否か。
    on = { -- Restore のトリガーとなるイベント。(:h events)
      'InsertEnter',
      'FocusGained',
    },
    file_pattern = nil, -- Restore が有効となるファイル名のパターン。 (nil は全ファイル)
    -- 例:
    -- file_pattern = { '*.md', '*.txt' },

    exclude_pattern = '[-a-zA-Z0-9=~+/?!@#$%%^&_(){}%[%];:<>]',
    -- ユーザーが Insert モードに移行すると、その瞬間のカーソルの位置が本プラグインによってチェックされます。
    -- そして、その位置からの前後 2 文字が `exclude_pattern` に含まれていた場合にのみ、
    -- Restore を実行しません。
    -- `exclude_pattern` のデフォルト値は半角英数と一般的な半角記号です。
  },

  os = nil, -- 'macos', 'windows', 'linux', または nil で自動判別。
  os_settings = { -- OS 毎の設定。
    macos = {
      enable = true,
      cmd_get = 'im-select', -- 現在の入力モードを取得するコマンド。
      cmd_set = 'im-select %s', -- 入力モードを変更するコマンド。(`%s` が入力モードで置換されます)
      normal_input = nil, -- Normalize で使用する入力モード。(nil で自動判別)
      -- 例:
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


## コマンド

`:AutoInputSwitch on|off`

機能全体の on/off を切り替えます。


`:AutoInputSwitchNormalize`

入力モードを手動でノーマライズします。


`:AutoInputSwitchRestore`

入力モードを手動でリストアします。


## ライセンス
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

