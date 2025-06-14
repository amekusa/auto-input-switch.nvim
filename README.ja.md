# auto-input-switch.nvim
![GitHub Tag](https://img.shields.io/github/v/tag/amekusa/auto-input-switch.nvim?label=stable&link=https%3A%2F%2Fgithub.com%2Famekusa%2Fauto-input-switch.nvim%2Ftags)

[English](README.md) / **日本語**

<img src="https://raw.githubusercontent.com/amekusa/assets/master/auto-input-switch.nvim/demo.gif">

これはキーボードの入力言語を様々なタイミングにおいて自動で切り替える Neovim プラグインです。
英語以外の言語によるライティング・エクスペリエンスを向上させます。

例えば、以下のようなことが実現可能です:

- Normal モード時は自動で入力言語を US（英数）にする。
- カーソル付近の文字の言語を判別し、対応する入力言語に自動で切り替える。
- Insert モードに入った際、自動で日本語入力に切り替える。（直前に日本語入力を使っていた場合）
- Neovim のウィンドウがフォーカスされた時に自動で入力言語を US（英数）にする。
- Neovim を終了した時に自動で入力言語を US（英数）にする。


## バージョン履歴

```
v4.1.0 - オプション追加: `os_settings.*.normal_input.cmd_set`,
                         `os_settings.*.lang_inputs.*.cmd_set`

         これらのオプションを設定することで、
         `os_settings.*.cmd_set` の値を入力言語毎にオーバーライドすることが可能になりました。

v4.0.0 - オプション追加: `popup.labels`
         これにより入力言語毎にポップアップ表示するラベルをカスタマイズすることが可能になりました。
       - オプション削除: `normalize.popup`
         新オプション `popup.labels.normal_input` に置き換えられました。
       - ポップアップ周りの軽微なバグを修正しました。
       - ポップアップ表示のパフォーマンスを改善しました。

v3.4.0 - オプション追加: `match.lines.exclude_pattern`
       - `match.lines` 機能の正しくない振る舞いを修正しました。
         行検索中、言語が照合するか否かに関わらず、空行以外の行に到達時に検索を終了するようになりました。

v3.3.0 - `os_settings.*.normal_input` にテーブルが指定可能になりました。
         例: normal_input = { 'com.apple.keylayout.ABC', 'eisu' },
         1 番目の文字列は入力言語の名前であり、`cmd_get` の出力結果と一致している必要があります。
         2 番目の文字列は実際に `cmd_set` に渡される文字列です。

       - `os_settings.*.lang_inputs` の各値にも `normal_input` 同様にテーブルが指定可能です。
       - `prefix` オプションを追加しました。
       - `popup.zindex` オプションを追加しました。
       - ポップアップが他のフローティングウィンドウが開くのを阻害することがある問題を修正しました。
       - `AutoInputSwitchRestore` と `AutoInputSwitchMatch` コマンドのエラーを修正しました。

v3.2.0 - "Popup" 機能を追加しました。
v3.1.0 - `match.lines` オプションを追加しました。
v3.0.0 - "Match" 機能を追加しました。
v2.2.0 - `async` オプションを追加しました。
v2.0.0 - オプション項目をいくつか追加/削除しました。
v1.0.0 - リリース。
```


## 互換性
NVIM v0.10.2+

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
  activate = true, -- 本プラグインの機能を有効にするか否か
  -- このフラグは `AutoInputSwitch on|off` コマンドでいつでも切り替え可能です。

  async = false, -- 入力言語切り替え時にシェルコマンド (`cmd_get/cmd_set`) の実行を非同期で行うか否か
  -- false: 同期実行(推奨)
  --        Insert モードと Normal モード間の切り替えを素早く繰り返した際などに僅かなラグが発生する場合があります。
  --  true: 非同期実行
  --        ラグは発生しませんが、同期実行よりも信頼性に劣ります。

  log = false, -- ログをファイルに出力するか否か
  -- `cmd_get/cmd_set` のデバッグに有用です。
  -- ログファイルは本プラグインの setup() 関数が呼び出される度に初期化されます。
  -- ログファイルのパス: ~/.local/state/nvim/auto-input-switch.log (Linux, macOS)
  --                     ~/AppData/Local/nvim-data/auto-input-switch.log (Windows)

  prefix = 'AutoInputSwitch', -- コマンド名のプリフィックス
  -- コマンド名を短くしたい場合、以下の設定を推奨:
  -- prefix = 'AIS',

  popup = {
    -- プラグインによって入力言語が変更された際、現在の入力言語名をポップアップ表示で知らせます。

    enable = true, -- ポップアップ表示を有効にするか否か
    duration = 1500, -- ポップアップを表示する時間 (ms)
    pad = true, -- 表示言語の前後に空白文字を入れるか否か
    hl_group = 'PmenuSel', -- ハイライトグループ

    -- ポップアップウィンドウの設定 (:h nvim_open_win())
    border = 'none', -- ウィンドウの枠のスタイル
    zindex = 50, -- レンダリングの優先度
    row = 1, -- 横位置のオフセット
    col = 0, -- 縦位置のオフセット
    relative = 'cursor', -- 何を位置の基準とするか: editor/win/cursor/mouse
    anchor = 'NW', -- どの角を基準位置に合わせるか
    -- 'NW' : 左上
    -- 'NE' : 右上
    -- 'SW' : 左下
    -- 'SE' : 右下

    labels = {
      normal_input = { 'A', 1 },
      -- Normalize 時に表示するポップアップのラベル。false で非表示。
      -- 1 つ目の値はラベルの文字列
      -- 2 つ目の値はラベルの文字列の長さ

      lang_inputs = {
        -- Restore と Match 時に表示するポップアップのラベル。各言語ごとに設定。
        -- フォーマットは `popup.labels.normal_input` と同様。
        Ja = { 'あ', 2 }, -- 日本語
        Zh = { '拼', 2 }, -- 中国語
        Ko = { '한', 2 }, -- 韓国語
      },
    },
  },

  normalize = {
    -- Insert モード以外のモード時、入力言語を強制的に半角英数に切り替えることができます。
    -- この機能を "Normalize" と呼称します。

    enable = true, -- Normalize を有効にするか否か
    on = { -- Normalize のトリガーとなるイベント (:h events)
      'InsertLeave',
      'BufLeave',
      'WinLeave',
      'FocusLost',
      'ExitPre',
    },
    file_pattern = false, -- Normalize が有効となるファイル名のパターン (false なら全ファイル)
    -- 例:
    -- file_pattern = { '*.md', '*.txt' },
  },

  restore = {
    -- "Normalize" が実行される際、本プラグインによって直前の入力言語が記憶されます。
    -- そしてユーザーが次に Insert モードに移行した瞬間、記憶していた入力言語を自動的に復元します。
    -- この機能を "Restore" と呼称します。

    enable = true, -- Restore を有効にするか否か
    on = { -- Restore のトリガーとなるイベント (:h events)
      'InsertEnter',
      'FocusGained',
    },
    file_pattern = false, -- Restore が有効となるファイル名のパターン (false なら全ファイル)
    -- 例:
    -- file_pattern = { '*.md', '*.txt' },

    exclude_pattern = '[-a-zA-Z0-9=~+/?!@#$%%^&_(){}%[%];:<>]',
    -- ユーザーが Insert モードに入ると、その瞬間のカーソルの位置が本プラグインによってチェックされます。
    -- そして、その位置と隣接する 2 文字のいずれかが `exclude_pattern` に含まれていた場合、
    -- Restore の実行をキャンセルします。
    -- `exclude_pattern` のデフォルト値は半角英数と一般的な半角記号です。
    -- この機能を無効にするには false をセットしてください。
  },

  match = {
    -- Insert モードに入った際、本プラグインはカーソル付近の文字の言語を判別し、
    -- その言語に対応した入力言語に自動で切り替えることができます。
    -- この機能を "Match" と呼称します。
    -- Match を有効にする場合、`restore.enable` を false にすることが推奨されます。
    -- Match はデフォルトでは無効に設定されています。

    enable = false, -- Match を有効にするか否か
    on = { -- Match のトリガーとなるイベント (:h events)
      'InsertEnter',
      'FocusGained',
    },
    file_pattern = false, -- Match が有効となるファイル名のパターン (false なら全ファイル)
    -- 例:
    -- file_pattern = { '*.md', '*.txt' },

    languages = {
      -- カーソル付近の文字と照合させる言語のリスト。使用したい言語の `enable` を true にしてください。
      -- `pattern` は正規表現の文字列です。その言語に対応するユニコードの範囲を指定すると良いでしょう。
      -- ユーザーが任意の言語を追加することも可能です。
      -- その場合は `os_settings[あなたのOS].lang_inputs` に、対応する入力言語も併せて追加する必要があります。
      Ru = { enable = false, priority = 0, pattern = '[\\u0400-\\u04ff]' },
      Ja = { enable = false, priority = 0, pattern = '[\\u3000-\\u30ff\\uff00-\\uffef\\u4e00-\\u9fff]' },
      Zh = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u4e00-\\u9fff\\u3400-\\u4dbf\\u3100-\\u312f]' },
      Ko = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u1100-\\u11ff\\u3130-\\u318f\\uac00-\\ud7af]' },
    },

    lines = {
      -- 現在の行が空か空白文字のみを含んでいる場合、
      -- 現在の行から上下の行に対して各言語の検索を行います。
      above = 2, -- 上に何行分、言語の検索を行うか
      below = 1, -- 下に何行分、言語の検索を行うか

      exclude_pattern = [[^\s*\([-+*:|>]\|[0-9]\+\.\)\s]],
      -- 検索対象の行が一つでもこの正規表現にマッチした場合、
      -- 言語の検索がただちにキャンセルされ、入力言語の変更も行われません。
      -- この機能は、マークダウン文書のリストやテーブル, 引用ブロック等を記述する際に有用です。
      -- false をセットすることでこの機能を無効にすることができます。
    },
  },

  os = false, -- 'macos', 'windows', 'linux', または false で自動判別
  os_settings = { -- OS 毎の設定
    macos = {
      enable = true,
      cmd_get = 'im-select', -- 現在の入力言語を取得するシェルコマンド
      cmd_set = 'im-select %s', -- 入力言語を変更するシェルコマンド (`%s` が入力言語で置換されます)
      normal_input = false, -- Normalize で使用する入力言語 (false なら自動判別)
      -- 例:
      -- normal_input = 'com.apple.keylayout.ABC',
      -- normal_input = 'com.apple.keylayout.US',
      -- normal_input = 'com.apple.keylayout.USExtended',

      -- 以下のようにテーブルを指定することも可能です:
      -- normal_input = { 'com.apple.keylayout.ABC', 'eisu' },
      --   1 番目の文字列は入力言語の名前であり、`cmd_get` の出力結果と一致している必要があります。
      --   2 番目の文字列は実際に `cmd_set` に渡される文字列です。
      --
	  -- また、`cmd_set` をオーバーライドすることも可能です:
      -- normal_input = { 'com.apple.keylayout.ABC', 'eisu', cmd_set = 'some-alternative-command %s' },

      lang_inputs = {
        -- `match.languages` 内の各言語に対応する入力言語のリスト。
        -- `normal_input` 同様、各値にテーブルを指定することも可能です。
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
      normal_input = false,
      lang_inputs = {},
    },
    linux = {
      enable = true,
      cmd_get = 'ibus engine',
      cmd_set = 'ibus engine %s',
      normal_input = false,
      lang_inputs = {},
    },
  },
})
```


## 設定例

```lua
-- 日本語, 中国語, 韓国語の Match を有効にする
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

入力言語を手動で Normalize します。


`:AutoInputSwitchRestore`

入力言語を手動で Restore します。


`:AutoInputSwitchMatch`

入力言語を手動で Match します。


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

