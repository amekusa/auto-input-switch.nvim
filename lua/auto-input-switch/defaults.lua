return {
  activate = true, -- Enable the plugin.
    -- You can toggle it anytime with the `:AutoInputSwitch on|off` command.

  async = false, -- Run shell commands (`cmd_get` / `cmd_set`) asynchronously?
    --   * false: Run synchronously (recommended).
    --            May cause slight lag if you switch rapidly between Insert and Normal mode.
    --   *  true: Run asynchronously. Removes lag but may be less reliable.

  log = false, -- Output logs to a file?
    -- Useful for debugging `cmd_get` / `cmd_set`.
    -- The log file is cleared every time `setup()` is called.
    -- 
    -- Log file path:
    --   * Linux/macOS: ~/.local/state/nvim/auto-input-switch.log
    --   *     Windows: ~/AppData/Local/nvim-data/auto-input-switch.log

  prefix = 'AutoInputSwitch', -- Prefix for command names.
    -- If you prefer shorter commands, set this to something like 'AIS'.

  popup = { -- When the plugin switches the input method, it can notify you with a popup.
    enable = true, -- Show popups?
    duration = 1500, -- How long the popup remains visible (ms).
    pad = true, -- Add leading and trailing spaces in popup text.
    hl_group = 'PmenuSel', -- Highlight group for the popup window.
    window = { -- Popup window configuration (:h nvim_open_win()).
      border = 'none', -- Border style.
      zindex = 50, -- Rendering priority (higher = drawn on top).
      row = 1, -- Horizontal offset from the anchor.
      col = 0, -- Vertical offset from the anchor.
      relative = 'cursor', -- Origin of the offsets.
        -- One of: 'editor', 'win', 'cursor', or 'mouse'.

      anchor = 'NW', -- Corner used to anchor the popup.
        --   * 'NW': Northwest
        --   * 'NE': Northeast
        --   * 'SW': Southwest
        --   * 'SE': Southeast

    },
    labels = { -- Popup label texts for various input methods.
      normal_input = 'A', -- Popup text for Normalize. Set false to disable.
      lang_inputs = { -- Popup texts for Restore and Match.
        Ja = 'あ', -- Popup text for Japanese input.
        Zh = '拼', -- Popup text for Chinese input.
        Ko = '한', -- Popup text for Korean input.
      },
    },
  },
  normalize = { -- Outside Insert mode, the plugin can force the input method to Latin.
    -- This feature is called "Normalize".

    enable = true, -- Enable Normalize?
    on = { -- Events that trigger Normalize (:h events).
      'BufLeave',
      'WinLeave',
      'FocusGained',
      'ExitPre',
      'QuitPre',
    },
    on_mode_change = { -- Mode transition patterns that trigger Normalize.
      -- If not false, Normalize is triggered by the 'ModeChanged' event.
      -- See:
      --   * :h autocmd-pattern
      --   * :h ModeChanged
      --   * :h mode()
      -- 
      -- Default:
      --   '[iR]:n' (From Insert/Replace to Normal mode)

      '[iR]:n',
    },
    filetypes = '*', -- Filetypes where Normalize is enabled.
      -- Example:
      --   filetypes = { 'markdown', 'text' },

    debounce = 500, -- Debounce time (ms). Prevents repeated Normalize triggers.
    buf_condition = nil, -- Optional function that decides whether Normalize is enabled for a buffer.
      -- Called on each buffer creation with its buffer number.
      -- Return true to enable Normalize for that buffer.
      -- Example:
      --   -- Enable only in listed buffers
      --   buf_condition = function(buf)
      --     return vim.bo[buf].buflisted
      --   end,

  },
  restore = { -- When Normalize is about to run, the plugin saves the current input method.
    -- When you next enter Insert or Replace mode, it restores that input method.
    -- This feature is called "Restore".

    enable = true, -- Enable Restore?
    on = { -- Events that trigger Restore (:h events).
      'FocusGained',
    },
    on_mode_change = { -- Mode transitions that trigger Restore.
      -- Default: 'n:[iR]' (From Normal to Insert/Replace mode)

      'n:[iR]',
    },
    filetypes = '*', -- Filetypes where Restore is enabled.
      -- Example:
      --   filetypes = { 'markdown', 'text' },

    debounce = 500, -- Debounce time (ms). Prevents repeated Restore triggers.
    buf_condition = nil, -- Function that decides whether Restore is enabled for a buffer.
      -- Called on every buffer creation.
      -- By default, returns true if the buffer is 'modifiable'.
      -- You can override this or disable it by setting false.

    exclude_pattern = [==[[-+a-zA-Z0-9@#$%^&/\\¥=~<>(){}\[\];:`]]==], -- Regex pattern checked before Restore runs.
      -- If nearby characters match this, Restore is canceled.
      -- Default: matches alphanumerics and common punctuation.
      -- Set false to disable this check.

  },
  match = { -- Detects the language of nearby characters on Insert/Replace mode entry
    -- and switches to the matching input method.
    -- This feature is called "Match".
    -- If Match and Restore trigger together, Match takes priority.
    -- Disabled by default.

    enable = false, -- Enable Match?
    on = { -- Events that trigger Match (:h events).
      'FocusGained',
    },
    on_mode_change = { -- Mode transitions that trigger Match.
      -- Default: '[nvV]:[iR]' (From Normal/Visual to Insert/Replace mode)

      '[nvV]:[iR]',
    },
    filetypes = '*', -- Filetypes where Match is enabled.
      -- Example:
      --   filetypes = { 'markdown', 'text' },

    debounce = 500, -- Debounce time (ms). Prevents repeated Match triggers.
    buf_condition = nil, -- Function that decides whether Match is enabled for a buffer.
      -- Called on buffer creation.
      -- By default, returns true if the buffer is 'modifiable'.
      -- You can override this or disable it by setting false.

    languages = { -- Languages to detect and match.
      -- Enable those you want to use.
      -- Each `pattern` must be a valid regex (Unicode ranges).
      -- Add custom languages if needed, and define them in `os_settings[OS].lang_inputs`.

      Ru = { -- Cyrillic range for Russian.
        enable = false,
        priority = 0,
        pattern = [==[[\u0400-\u04ff]]==],
      },
      Ja = { -- Unicode ranges for Japanese.
        enable = false,
        priority = 0,
        pattern = [==[[\u3000-\u30ff\uff00-\uffef\u4e00-\u9fff]]==],
      },
      Zh = { -- Unicode ranges for Chinese.
        enable = false,
        priority = 0,
        pattern = [==[[\u3000-\u303f\u4e00-\u9fff\u3400-\u4dbf\u3100-\u312f]]==],
      },
      Ko = { -- Unicode ranges for Korean.
        enable = false,
        priority = 0,
        pattern = [==[[\u3000-\u303f\u1100-\u11ff\u3130-\u318f\uac00-\ud7af]]==],
      },
    },
    lines = { -- When the current line is empty or whitespace-only,
      -- Match searches nearby lines as well.

      above = 1, -- Number of lines above to search.
      below = 1, -- Number of lines below to search.
      exclude_pattern = [==[^\s*\%([-+*:|>]\|[0-9]\+\.\)\s]==], -- Regex pattern for lines that stop language detection.
        -- Useful for Markdown lists or blockquotes.
        -- Set false to disable.

    },
  },
  os = false, -- Operating system to use for input-method control.
    -- Accepts 'macos', 'windows', 'linux', or false for auto-detection.

  os_settings = { -- OS-specific settings for input-method commands and mappings.
    macos = {
      enable = true, -- Enable macOS-specific input-method handling.
      cmd_get = 'im-select', -- Command to get the current input method ID.
      cmd_set = 'im-select %s', -- Command to set a new input method (%s will be replaced with the target ID).
      normal_input = false, -- Input method used for Normalize (false = auto-detect).
        -- Examples:
        --   normal_input = 'com.apple.keylayout.ABC',
        --   normal_input = 'com.apple.keylayout.US',
        --   normal_input = 'com.apple.keylayout.USExtended',
        -- You can also use a table like this:
        --   normal_input = { 'com.apple.keylayout.ABC', 'eisu' },
        --   The first string must match `cmd_get` output; the second is passed to `cmd_set`.

      lang_inputs = { -- Input methods corresponding to `match.languages`.
        -- Each entry can also be a table like `normal_input`.

        Ru = 'com.apple.keylayout.Russian', -- Input method ID for Russian.
        Ja = 'com.apple.inputmethod.Kotoeri.Japanese', -- Input method ID for Japanese.
        Zh = 'com.apple.inputmethod.SCIM.ITABC', -- Input method ID for Chinese.
        Ko = 'com.apple.inputmethod.Korean.2SetKorean', -- Input method ID for Korean.
      },
    },
    windows = {
      enable = true, -- Enable Windows-specific input-method handling.
      cmd_get = 'im-select.exe', -- Command to get the current input method ID.
      cmd_set = 'im-select.exe %s', -- Command to set a new input method (%s will be replaced with the target ID).
      normal_input = false, -- Input method for Normalize (false = auto-detect).
        -- Example:
        --   normal_input = '1033', -- US English

      lang_inputs = { -- Input methods corresponding to `match.languages`.
        Ru = '1049', -- Input method ID for Russian.
        Ja = '1041', -- Input method ID for Japanese.
        Zh = '2052', -- Input method ID for Chinese.
        Ko = '1042', -- Input method ID for Korean.
      },
    },
    linux = {
      enable = true, -- Enable Linux-specific input-method handling.
      cmd_get = 'ibus engine', -- Command to get the current input method ID.
      cmd_set = 'ibus engine %s', -- Command to set a new input method (%s will be replaced with the target ID).
      normal_input = false, -- Input method for Normalize (false = auto-detect).
        -- Example:
        --   normal_input = 'xkb:us::eng', -- US English.

      lang_inputs = { -- Input methods corresponding to `match.languages`.
        Ru = 'xkb:ru::rus', -- Input method ID for Russian.
        Ja = 'mozc-jp', -- Input method ID for Japanese.
        Zh = 'libpinyin', -- Input method ID for Chinese.
        Ko = 'hangul', -- Input method ID for Korean.
      },
    },
  },
}