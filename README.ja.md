<!--TRUNCATE:START-->
[English](README.md) / **日本語**

```

   ▀█▀██              ▀██▀                 ▄█▀▀▄█
   ▐▌ ██  █ █ ▀█▀ █▀▄  ██  █▀▄ █▀▄ █ █ ▀█▀ ██   █ █ █ █ █ ▀█▀ ▄▀▀ █ █
   █▄▄██  █ █  █  █ █  ██  █ █ █▄█ █ █  █   ▀▀▄▄  █ █ █ █  █  █   █▀█
  ▐▌  ██  ▀▄█  █  ▀▄█  ██  █ █ █   ▀▄█  █  █   ██ ▀▄█▄█ █  █  ▀▄▄ █ █
 ▄█▄ ▄██▄ ━━━━━━━━━━━ ▄██▄ ━━━━━━━━━━━━━━━ █▀▄▄█▀ ━━━━━━━━━━━━━━━━━━ ★ NVIM

```
![GitHub Tag](https://img.shields.io/github/v/tag/amekusa/auto-input-switch.nvim?label=stable&link=https%3A%2F%2Fgithub.com%2Famekusa%2Fauto-input-switch.nvim%2Ftags)

![Demo Gif](https://raw.githubusercontent.com/amekusa/assets/master/auto-input-switch.nvim/demo.gif)

<!--TRUNCATE:END-->
入力言語 (IME) を状況に合わせて自動で切り替える Neovim プラグインです。  
英語以外の言語で文章を書く際、頻繁に入力言語を切り替える煩わしさを軽減します。

macOS, Windows, Linux に対応しています。

> [!WARNING]  
> **v5.0.0 の変更点**  
> v4.x から更新する場合は [変更履歴](#changelog) で詳細を確認してください。


## 機能 <!-- #features -->
- **Normalize**:  
  Insert 以外のモード時、入力言語を英数に強制します。
- **Restore**:  
  Normalize 後に Insert モードに戻ると、入力言語を元の状態に復帰させます。
- **Match**:  
  カーソル付近の文字の言語を検知し、一致する入力言語に自動で切り替えます。
- **Popup notifications**:  
  プラグインが入力言語を切り替える際、ポップアップ表示で知らせます。


## インストール <!-- #installation -->
[lazy.nvim](https://github.com/folke/lazy.nvim) を使用する場合:

```lua
require('lazy').setup({
  {
    'amekusa/auto-input-switch.nvim',
    config = function()
      require('auto-input-switch').setup({
        -- 任意のオプション
      })
    end
  },
})
```


## 設定 <!-- #configuration -->
以下より全ての設定項目が確認できます。

- [`auto-input-switch-options.ja.txt`](doc/auto-input-switch-options.ja.txt)
- [`auto-input-switch-defaults.ja.txt`](doc/auto-input-switch-defaults.ja.txt)

設定例: 日本語, 中国語, 韓国語に対する **Match** を有効にする:

```lua
require('auto-input-switch').setup({
  match = {
    enable = true,
    languages = {
      Ja = { enable = true, priority = 1 },
      Zh = { enable = true, priority = 0 },
      Ko = { enable = true },
    }
  },
  restore = {
    enable = false,
      -- Match を有効にする場合、混乱を避けるため
      -- Restore を無効にすることを推奨します。
  },
})
```

> [!NOTE]
> 日本語と中国語はユニコード範囲を一部共有しているため、
> `priority` でそれぞれの優先度を指定することを推奨します。


## 動作環境 <!-- #requirements -->
- **Neovim:** v0.10+
- **OS:** macOS, Windows, Linux

コマンドラインで入力言語を切り替えるソフトが必要です。
デフォルト設定の場合:

- macOS / Windows: [im-select](https://github.com/daipeihust/im-select)  
  (macOS の場合、[macism](https://github.com/laishulu/macism) の方がいいかもしれません。)
- Linux: [ibus](https://github.com/ibus/ibus)


<!--TRUNCATE:START-->
## ドキュメント <!-- #documents -->
- [プラグインについて](doc/auto-input-switch.ja.txt)
- [オプション](doc/auto-input-switch-options.ja.txt)
- [デフォルト設定](doc/auto-input-switch-defaults.ja.txt)
- [コマンド](doc/auto-input-switch-commands.ja.txt)


<!--TRUNCATE:END-->
## 変更履歴 <!-- #changelog -->

### v5.0.0
過去のバージョンとは**非互換の変更**が含まれます。  
アップグレードの際は注意してください。

**非互換の変更**:
- `*.file_pattern` を `*.filetypes` に変更 (拡張子ではなくファイルタイプ名を指定)。
- `*.on_mode_change` を追加。  
  それに伴い `*.on` のデフォルト値から `InsertEnter/InsertLeave` を削除。
- `restore.exclude_pattern` を正規表現に変更。
- ポップウィンドウの設定を `popup.*` から `popup.window.*` へ移動。

**互換性のある変更**:
- `popup.labels.*` に単純な文字列を指定可能に (幅は自動計算されます)。
- 追加オプション: `normalize.debounce`, `restore.debounce`, `match.debounce`, `*.buf_condition`.
- 追加コマンド:
  - `:AutoInputSwitchBuf on|off`
  - `:AutoInputSwitchBufNormalize on|off`
  - `:AutoInputSwitchBufRestore on|off`
  - `:AutoInputSwitchBufMatch on|off`

<details>
<summary>過去の変更:</summary>

- v4.1.0 – Override `cmd_set` per input method
- v4.0.0 – Custom popup labels, bug fixes
- v3.0.0 – Added Match feature
- v2.0.0 – Added async support
- v1.0.0 – Initial release

</details>


## License
MIT © 2025 [Satoshi Soma](https://github.com/amekusa)

