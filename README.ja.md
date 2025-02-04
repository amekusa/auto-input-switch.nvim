# auto-input-switch.nvim
![GitHub Tag](https://img.shields.io/github/v/tag/amekusa/auto-input-switch.nvim?label=stable&link=https%3A%2F%2Fgithub.com%2Famekusa%2Fauto-input-switch.nvim%2Ftags)

[English](README.md) / **日本語**

これはキーボードの入力モードを様々なタイミングにおいて自動で切り替える Neovim プラグインです。
英語以外の言語によるライティング・エクスペリエンスを向上させます。

例えば、以下のようなことが実現可能です:

- Normal モード時は自動で入力モードを US（英数）にする。
- カーソル付近の文字の言語を判別し、対応する入力モードに自動で切り替える。
- Insert モードに入った際、自動で日本語入力モードに戻る。（直前に日本語入力モードを使っていた場合）
- Neovim のウィンドウがフォーカスされた時に自動で入力モードを US（英数）にする。
- Neovim を終了した時に自動で入力モードを US（英数）にする。


## バージョン履歴
- v3.0.0
  - "Match" 機能を追加しました。
- v2.2.0
  - `async` オプションを追加しました。
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
    file_pattern = nil, -- Restore が有効となるファイル名のパターン。(nil は全ファイル)
    -- 例:
    -- file_pattern = { '*.md', '*.txt' },

    exclude_pattern = '[-a-zA-Z0-9=~+/?!@#$%%^&_(){}%[%];:<>]',
    -- ユーザーが Insert モードに入ると、その瞬間のカーソルの位置が本プラグインによってチェックされます。
    -- そして、その位置からの前後 2 文字が `exclude_pattern` に含まれていた場合にのみ、
    -- Restore の実行をキャンセルします。
    -- `exclude_pattern` のデフォルト値は半角英数と一般的な半角記号です。
    -- この機能を無効にするには nil をセットしてください。
  },

  match = {
    -- Insert モードに入った際、本プラグインはカーソル付近の文字の言語を判別し、
    -- その言語に対応した入力モードに自動で切り替えることができます。
    -- この機能を "Match" と呼称します。
    -- Match を有効にする場合、`restore.enable` を false にすることが推奨されます。
    -- Match はデフォルトでは無効に設定されています。

    enable = false, -- Match を有効にするか否か。
    on = { -- Match のトリガーとなるイベント。(:h events)
      'InsertEnter',
      'FocusGained',
    },
    file_pattern = nil, -- Match が有効となるファイル名のパターン。(nil は全ファイル)
    -- 例:
    -- file_pattern = { '*.md', '*.txt' },

    languages = {
      -- カーソル付近の文字と照合させる言語のリスト。使用したい言語の `enable` を true にしてください。
      -- `pattern` は正規表現の文字列です。その言語に対応するユニコードの範囲を指定すると良いでしょう。
      -- ユーザーが任意の言語を追加することも可能です。
      -- その場合は `os_settings[あなたのOS].lang_inputs` に、対応する入力モードも併せて追加する必要があります。
      Ru = { enable = false, priority = 0, pattern = '[\\u0400-\\u04ff]' },
      Ja = { enable = false, priority = 0, pattern = '[\\u3000-\\u30ff\\uff00-\\uffef\\u4e00-\\u9fff]' },
      Zh = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u4e00-\\u9fff\\u3400-\\u4dbf\\u3100-\\u312f]' },
      Ko = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u1100-\\u11ff\\u3130-\\u318f\\uac00-\\ud7af]' },
    },
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

      lang_inputs = {
        -- `match.languages` 内の各言語に対応する入力モードのリスト。
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


## 設定例

```lua
-- 日本語, 中国語, 韓国語の Match を有効にする。
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

日本語と中国語は部分的にユニコード範囲が被っているので、
`priority` の数値をそれぞれの言語に指定しておくことは重要です。


## コマンド

`:AutoInputSwitch on|off`

機能全体の on/off を切り替えます。


`:AutoInputSwitchNormalize`

入力モードを手動で Normalize します。


`:AutoInputSwitchRestore`

入力モードを手動で Restore します。


`:AutoInputSwitchMatch`

入力モードを手動で Match します。


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

