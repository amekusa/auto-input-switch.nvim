return {
	activate = true, -- Enable the plugin?
	-- You can toggle this with `AutoInputSwitch on|off` command at any time.

	async = false, -- Run the shell-commands (`cmd_get/cmd_set`) to switch inputs asynchronously?
	-- false: Runs synchronously. (Recommended)
	--        You may encounter subtle lags if you switch between Insert-mode and Normal-mode very rapidly.
	--  true: Runs asynchronously.
	--        No lags, but less reliable than synchronous.

	log = false, -- Output logs to a file?
	-- This is useful for debugging `cmd_get/cmd_set`.
	-- The log file gets wiped out every time the plugin's setup() function is called.
	-- The log file path: ~/.local/state/nvim/auto-input-switch.log (Linux, macOS)
	--                    ~/AppData/Local/nvim-data/auto-input-switch.log (Windows)

	prefix = 'AutoInputSwitch', -- Prefix of the command names
	-- If you prefer shorter command names, use this:
	-- prefix = 'AIS',

	popup = {
		-- When the plugin changed the input source, it can indicate the language of the current input source with a popup.

		enable = true, -- Show popups?
		duration = 1500, -- How long does a popup remain visible? (ms)
		pad = true, -- Whether to add leading & trailing spaces
		hl_group = 'PmenuSel', -- Highlight group

		win = {
			-- Popup window configuration (:h nvim_open_win())
			border = 'none', -- Style of the window border
			zindex = 50, -- Rendering priority
			row = 1, -- Horizontal offset
			col = 0, -- Vertical offset
			relative = 'cursor', -- The offsets are relative to: editor/win/cursor/mouse
			anchor = 'NW', -- Which corner should be used to align a popup window?
				-- 'NW' : Northwest
				-- 'NE' : Northeast
				-- 'SW' : Southwest
				-- 'SE' : Southeast
		},

		labels = {
			normal_input = { 'A', 1 },
			-- Popup text to show on "Normalize". Set false to disable it.
			-- The 1st value is the content string.
			-- The 2nd value is the length of the content string.

			lang_inputs = {
				-- Popup texts to show on "Restore" and "Match".
				-- The format of each entry is the same as that of `popup.labels.normal_input`.
				Ja = { 'あ', 2 }, -- For Japanese
				Zh = { '拼', 2 }, -- For Chinese
				Ko = { '한', 2 }, -- For Korean
			},
		},
	},

	normalize = {
		-- Outside of Insert-mode, the plugin can force your input source to be the latin one.
		-- We call this feature "Normalize".

		enable = true, -- Enable Normalize?
		on = { -- Events to trigger Normalize (:h events)
			'BufLeave',
			'WinLeave',
			'FocusLost',
			'FocusGained',
			'ExitPre',
			'QuitPre',
		},
		on_mode_change = {
			-- If this is not false, Normalize is triggered by `ModeChanged` event.
			-- This option determines what modes switched from/to can trigger Normalize.
			-- For the syntax, see:
			--   :h autocmd-pattern
			--   :h ModeChanged
			--   :h mode()
			'[iR]:n', -- from Insert/Replace mode to Normal mode
		},
		filetypes = '*', -- Filetypes to enable Normalize
		-- Example:
		-- filetypes = { 'markdown', 'text' },

		debounce = 1000, -- Debounce time (ms)
		-- This prevents the plugin from attempting Normalize multiple times too quickly in a row.

		buf_condition = nil, -- Optional function that determines whether to enable Normalize for buffer
		-- This function gets called on every buffer creation.
		-- Example: This enables Normalize only in listed buffers
		-- buf_condition = function(buf)
		--   return vim.bo[buf].buflisted
		-- end,
	},

	restore = {
		-- When a Normalize is about to happen, the plugin saves the state of the input source at the moment.
		-- Then, the next time you enter Insert-mode, the plugin automatically restores the saved state.
		-- We call this feature "Restore".

		enable = true, -- Enable Restore?
		on = { -- Events to trigger Restore (:h events)
			'FocusGained',
		},
		on_mode_change = {
			'n:[iR]', -- from Normal mode to Insert/Replace mode
		},
		filetypes = '*', -- Filetypes to enable Restore
		-- Example:
		-- filetypes = { 'markdown', 'text' },

		debounce = 1000, -- Debounce time (ms)
		-- This prevents the plugin from attempting Restore multiple times too quickly in a row.

		buf_condition = nil, -- Function that determines whether to enable Restore for buffer
		-- This function gets called on every buffer creation.
		-- By default, it checks whether the buffer is 'modifiable'.
		-- Set false to skip this check.

		exclude_pattern = '[-+%w@#$%%^&/\\¥=~<>(){}%[%];:`]',
		-- When a Restore is about to happen, the plugin checks the characters near the cursor at the moment.
		-- And if the characters match with this pattern (NOT regex, but Lua's standard string pattern),
		-- the plugin cancels the Restore, leaving the input source unchanged.
		-- The default pattern includes a whole alphanumeric characters and common punctuation symbols with a few exceptions.
		-- Set false to disable this feature.
	},

	match = {
		-- When you enter Insert-mode, the plugin can detect the language of the characters adjacent to the cursor at the moment.
		-- Then, it can automatically switch the input source to the one that matches the detected language.
		-- We call this feature "Match".
		-- If both Match and Restore happen at the same time, Match is always prioritized.
		-- To avoid confusion, we recommend to set `restore.enable` to false.
		-- This feature is disabled by default.

		enable = false, -- Enable Match?
		on = { -- Events to trigger Match (:h events)
			'FocusGained',
		},
		on_mode_change = {
			'[nvV]:[iR]', -- from Normal mode to Insert/Replace mode
		},
		filetypes = '*', -- Filetypes to enable Match
		-- Example:
		-- filetypes = { 'markdown', 'text' },

		debounce = 1000, -- Debounce time (ms)
		-- This prevents the plugin from attempting Match multiple times too quickly in a row.

		buf_condition = nil, -- Function that determines whether to enable Match for buffer
		-- This function gets called on every buffer creation.
		-- By default, it checks whether the buffer is 'modifiable'.
		-- Set false to skip this check.

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
			-- the plugin also searches the languages in the lines above/below the current line.
			above = 2, -- How many lines above the current line to search in
			below = 1, -- How many lines below the current line to search in

			exclude_pattern = [[^\s*\%([-+*:|>]\|[0-9]\+\.\)\s]],
			-- If any of the lines above/below in the searching range match with this regex pattern,
			-- the plugin immediately stops searching the languages, leaving the input source unchanged.
			-- This is useful for writing lists, tables, or blockquotes in a markdown document.
			-- Set false to disable this feature.
		},
	},

	os = false, -- 'macos', 'windows', 'linux', or false to auto-detect
	os_settings = { -- OS-specific settings
		macos = {
			enable = true,
			cmd_get = 'im-select', -- Shell-command to get the current input source
			cmd_set = 'im-select %s', -- Shell-command to set the new input source (Use `%s` as a placeholder for the input source)
			normal_input = false, -- Name of the input source for Normalize (Set false to auto-detect)
			-- Examples:
			-- normal_input = 'com.apple.keylayout.ABC',
			-- normal_input = 'com.apple.keylayout.US',
			-- normal_input = 'com.apple.keylayout.USExtended',

			-- You can also use a table like this:
			-- normal_input = { 'com.apple.keylayout.ABC', 'eisu' },
			--   The 1st string is the name of the input source, which should match with the output of `cmd_get`.
			--   The 2nd string is what is actually passed to `cmd_set`.
			--
			-- Additionally, you can override `cmd_set` like this:
			-- normal_input = { 'com.apple.keylayout.ABC', 'eisu', cmd_set = 'some-alternative-command %s' },

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
}

