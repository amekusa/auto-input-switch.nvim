# auto-input-switch.nvim

  ▀█▀██              ▀██▀                 ▄█▀▀▄█
  ▐▌ ██  █ █ ▀█▀ █▀▄  ██  █▀▄ █▀▄ █ █ ▀█▀ ██   █ █ █ █ █ ▀█▀ ▄▀▀ █ █
  █▄▄██  █ █  █  █ █  ██  █ █ █▄█ █ █  █   ▀▀▄▄  █ █ █ █  █  █   █▀█
 ▐▌  ██  ▀▄█  █  ▀▄█  ██  █ █ █   ▀▄█  █  █   ██ ▀▄█▄█ █  █  ▀▄▄ █ █
▄█▄ ▄██▄ ━━━━━━━━━━━ ▄██▄ ━━━━━━━━━━━━━━━ █▀▄▄█▀ ━━━━━━━━━━━━━━━━━━ ★ NVIM

![GitHub Tag](https://img.shields.io/github/v/tag/amekusa/auto-input-switch.nvim?label=stable&link=https%3A%2F%2Fgithub.com%2Famekusa%2Fauto-input-switch.nvim%2Ftags)

**English** / [日本語](README.ja.md)

<img src="https://raw.githubusercontent.com/amekusa/assets/master/auto-input-switch.nvim/demo.gif">

A Neovim plugin that **automatically switches your input method** (IME / input source) based on context.  
It removes the friction of constantly toggling between English and non-English input methods when coding, writing, or taking notes.

Works on **macOS, Windows, and Linux**.  

---

⚠️ **Breaking changes in v5.0.0**  
If you’re upgrading from v4.x or earlier, please check the [Changelog](#changelog) for details.

---

## Features
- **Normalize** – Always return to Latin input (e.g. US keyboard) outside of Insert mode.  
- **Restore** – When you return to Insert mode, restore the input method you were using last time.  
- **Match** – Detect nearby text and automatically switch to the matching input method (Japanese, Chinese, Korean, Russian, …).  
- **Popup notifications** – Show a small popup whenever the plugin switches your input method.  

---

## Installation
With [lazy.nvim](https://github.com/folke/lazy.nvim):

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

---

## Configuration
This plugin is highly configurable.  
See [`defaults.lua`](./lua/auto-input-switch/defaults.lua) for all available options.  

Example: enable **Match** for Japanese, Chinese, and Korean:

```lua
require('auto-input-switch').setup({
  restore = { enable = false }, -- disable Restore to avoid confusion
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

Note: Since Japanese and Chinese share some Unicode ranges, it’s recommended to set `priority` to control which language takes precedence.

---

## Compatibility

- **Neovim:** v0.10+  
- **OS:** macOS, Windows, Linux  

### Prerequisites
You need a commanline program to switch input methods in the background.  
With the default config:

- macOS / Windows: [im-select](https://github.com/daipeihust/im-select)  
  (Alternatively, [macism](https://github.com/laishulu/macism) may work better on macOS.)  
- Linux: [ibus](https://github.com/ibus/ibus)  

---

## Commands

| Command | Description |
|---------|-------------|
| `:AutoInputSwitch on/off` | Enable or disable the plugin globally |
| `:AutoInputSwitchNormalize` | Normalize to the default Latin input |
| `:AutoInputSwitchRestore` | Restore the last used input method |
| `:AutoInputSwitchMatch` | Match input method based on nearby text |

Buffer-local versions are also available (see the [Changelog](#changelog)).

---

## Changelog

### v5.0.0
This release includes **major breaking changes**.  
If you’re upgrading, please review carefully.

**Breaking Changes**
- Replaced `*.file_pattern` with `*.filetypes` (takes filetype names, not extensions).  
- New `*.on_mode_change` options replace some `InsertEnter/InsertLeave` defaults.  
- `restore.exclude_pattern` now uses regex (not Lua patterns).  
- Popup window options moved from `popup.*` → `popup.window.*`.  

**Non-breaking Changes**
- `popup.labels.*` simplified (accepts plain strings).  
- New options: `normalize.debounce`, `restore.debounce`, `match.debounce`, `*.buf_condition`.  
- New buffer-local commands:  
  - `:AutoInputSwitchBuf on|off`  
  - `:AutoInputSwitchBufNormalize on|off`  
  - `:AutoInputSwitchBufRestore on|off`  
  - `:AutoInputSwitchBufMatch on|off`  

<details>
<summary>Older releases</summary>

- v4.1.0 – Override `cmd_set` per input method  
- v4.0.0 – Custom popup labels, bug fixes  
- v3.0.0 – Added Match feature  
- v2.0.0 – Added async support  
- v1.0.0 – Initial release  

</details>

---

## License
MIT © 2025 [Satoshi Soma](https://github.com/amekusa)
