return {
	activate = true, -- Enable the plugin.
	-- You can toggle it anytime with the `:AutoInputSwitch on|off` command.

	async = false, -- Run shell commands (`cmd_get` / `cmd_set`) asynchronously?
	-- false: Run synchronously (recommended).
	--        May cause slight lag if you switch rapidly between Insert and Normal mode.
	--  true: Run asynchronously.
	--        Removes lag but may be less reliable.

	log = false, -- Output logs to a file?
	-- Useful for debugging `cmd_get` / `cmd_set`.
	-- The log file is cleared every time `setup()` is called.
	-- Log file path: ~/.local/state/nvim/auto-input-switch.log (Linux, macOS)
	--                ~/AppData/Local/nvim-data/auto-input-switch.log (Windows)

	prefix = 'AutoInputSwitch', -- Prefix for command names.
	-- If you prefer shorter commands, set this:
	-- prefix = 'AIS',

	popup = {
		-- When the plugin switches the input source, it can notify you with a popup.

		enable = true, -- Show popups?
		duration = 1500, -- How long the popup remains visible (ms).
		pad = true, -- Add leading and trailing spaces.
		hl_group = 'PmenuSel', -- Highlight group.

		window = {
			-- Popup window configuration (:h nvim_open_win())
			border = 'none', -- Border style.
			zindex = 50, -- Rendering priority.
			row = 1, -- Horizontal offset.
			col = 0, -- Vertical offset.
			relative = 'cursor', -- Origin of the offsets. (editor / win / cursor / mouse)
			anchor = 'NW', -- Corner used to anchor the popup.
				-- 'NW' : Northwest
				-- 'NE' : Northeast
				-- 'SW' : Southwest
				-- 'SE' : Southeast
		},

		labels = {
			normal_input = 'A', -- Popup text for Normalize. Set false to disable.
			lang_inputs = {
				-- Popup texts for Restore and Match.
				Ja = 'あ', -- Japanese
				Zh = '拼', -- Chinese
				Ko = '한', -- Korean
			},
		},
	},

	normalize = {
		-- Outside Insert mode, the plugin can force the input source to Latin.
		-- This feature is called "Normalize".

		enable = true, -- Enable Normalize?
		on = { -- Events that trigger Normalize (:h events)
			'BufLeave',
			'WinLeave',
			'FocusGained',
			'ExitPre',
			'QuitPre',
		},
		on_mode_change = {
			-- If not false, Normalize is triggered by `ModeChanged` event.
			-- This option defines which mode transitions trigger it.
			-- See :h autocmd-pattern
			--     :h ModeChanged
			--     :h mode()
			'[iR]:n', -- From Insert/Replace to Normal mode.
		},
		filetypes = '*', -- Filetypes where Normalize is enabled.
		-- Example:
		-- filetypes = { 'markdown', 'text' },

		debounce = 500, -- Debounce time (ms).
		-- Prevents Normalize from firing too frequently.

		buf_condition = nil, -- Optional function that decides whether Normalize is enabled for a buffer.
		-- Called on every buffer creation with the buffer number as the argument.
		-- Return true to enable Normalize for that buffer.
		-- Example: Enable only in listed buffers:
		-- buf_condition = function(buf)
		--   return vim.bo[buf].buflisted
		-- end,
	},

	restore = {
		-- When Normalize is about to run, the plugin memorizes the current input source.
		-- The next time you enter Insert or Replace mode, it restores that memorized input source.
		-- This feature is called "Restore".

		enable = true, -- Enable Restore?
		on = { -- Events that trigger Restore (:h events)
			'FocusGained',
		},
		on_mode_change = {
			'n:[iR]', -- From Normal to Insert/Replace mode.
		},
		filetypes = '*', -- Filetypes where Restore is enabled.
		-- Example:
		-- filetypes = { 'markdown', 'text' },

		debounce = 500, -- Debounce time (ms).
		-- Prevents Restore from firing too frequently.

		buf_condition = nil, -- Function that decides whether Restore is enabled for a buffer.
		-- Called on every buffer creation with the buffer number as the argument.
		-- By default, it returns true only if the buffer is 'modifiable'.
		-- You can overwrite this function with your own, or disable it entirely by setting false.

		exclude_pattern = [===[[-+a-zA-Z0-9@#$%^&/\\¥=~<>(){}\[\];:`]]===],
		-- Before Restore runs, the plugin checks characters near the cursor.
		-- If they match this regex pattern, Restore is canceled and the input source is left unchanged.
		-- Default: matches alphanumeric characters and common punctuation.
		-- Set false to disable this check.
	},

	match = {
		-- When you enter Insert or Replace mode, the plugin can detect the language of characters
		-- near the cursor and switch to the matching input source.
		-- This feature is called "Match".
		-- If Match and Restore trigger at the same time, Match takes priority.
		-- To avoid confusion, consider disabling Restore if you enable Match.
		-- Disabled by default.

		enable = false, -- Enable Match?
		on = { -- Events that trigger Match (:h events)
			'FocusGained',
		},
		on_mode_change = {
			'[nvV]:[iR]', -- From Normal/Visual to Insert/Replace mode.
		},
		filetypes = '*', -- Filetypes where Match is enabled.
		-- Example:
		-- filetypes = { 'markdown', 'text' },

		debounce = 500, -- Debounce time (ms).
		-- Prevents Match from firing too frequently.

		buf_condition = nil, -- Function that decides whether Match is enabled for a buffer.
		-- Called on every buffer creation with the buffer number as the argument.
		-- By default, it returns true only if the buffer is 'modifiable'.
		-- You can overwrite this function with your own, or disable it entirely by setting false.

		languages = {
			-- Languages to detect. Enable those you want to use.
			-- `pattern` must be a valid regex string (use Unicode ranges).
			-- You can also add custom languages.
			-- If you do, also add their input sources to `os_settings[OS].lang_inputs`.
			Ru = { enable = false, priority = 0, pattern = '[\\u0400-\\u04ff]' },
			Ja = { enable = false, priority = 0, pattern = '[\\u3000-\\u30ff\\uff00-\\uffef\\u4e00-\\u9fff]' },
			Zh = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u4e00-\\u9fff\\u3400-\\u4dbf\\u3100-\\u312f]' },
			Ko = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u1100-\\u11ff\\u3130-\\u318f\\uac00-\\ud7af]' },
		},

		lines = {
			-- If the current line is empty or whitespace-only,
			-- Match also searches lines above and below.
			above = 1, -- Number of lines above to search.
			below = 1, -- Number of lines below to search.

			exclude_pattern = [[^\s*\%([-+*:|>]\|[0-9]\+\.\)\s]],
			-- If any surrounding line matches this regex, language detection stops
			-- and the input source is left unchanged.
			-- Useful for lists, tables, or blockquotes in Markdown.
			-- Set false to disable.
		},
	},

	os = false, -- 'macos', 'windows', 'linux', or false to auto-detect.
	os_settings = { -- OS-specific settings

		macos = {
			enable = true,
			cmd_get = 'im-select', -- Command to get the current input source.
			cmd_set = 'im-select %s', -- Command to set a new input source (`%s` is replaced).
			normal_input = false, -- Input source for Normalize (false = auto-detect).
			-- Examples:
			-- normal_input = 'com.apple.keylayout.ABC',
			-- normal_input = 'com.apple.keylayout.US',
			-- normal_input = 'com.apple.keylayout.USExtended',

			-- You can also use a table like this:
			-- normal_input = { 'com.apple.keylayout.ABC', 'eisu' },
			--   The 1st string must match `cmd_get` output.
			--   The 2nd string is passed to `cmd_set`.
			-- You can override `cmd_set` too, like this:
			-- normal_input = { 'com.apple.keylayout.ABC', 'eisu', cmd_set = 'other-command %s' },

			lang_inputs = {
				-- Input sources corresponding to `match.languages`.
				-- Each entry can also be a table like `normal_input`.
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
			normal_input = false, -- Auto-detect.
			-- normal_input = '1033', -- US English.

			lang_inputs = {
				Ru = '1049',
				Ja = '1041',
				Zh = '2052',
				Ko = '1042',
			},
		},

		linux = {
			enable = true,
			cmd_get = 'ibus engine',
			cmd_set = 'ibus engine %s',
			normal_input = false, -- Auto-detect.
			-- normal_input = 'xkb:us::eng', -- US English.

			lang_inputs = {
				Ru = 'xkb:ru::rus',
				Ja = 'mozc-jp',
				Zh = 'libpinyin',
				Ko = 'hangul',
			},
		},
	},
}

