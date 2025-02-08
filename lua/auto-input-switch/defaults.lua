return {
	activate = true, -- Activate the plugin?
	-- You can toggle this with `AutoInputSwitch on|off` command at any time.

	async = false, -- Run `cmd_get` & `cmd_set` asynchronously?
	-- false: Runs synchronously. (Recommended)
	--        You may encounter subtle lags if you switch between Insert-mode and Normal-mode very rapidly.
	--  true: Runs asynchronously.
	--        No lags, but less reliable than synchronous.

	normalize = {
		-- In Normal-mode or Visual-mode, you always want the input source to be alphanumeric, regardless of your keyboard's locale.
		-- The plugin can automatically switch the input source to the alphanumeric one when you escape from Insert-mode to Normal-mode.
		-- We call this feature "Normalize".

		enable = true, -- Enable Normalize?
		on = { -- Events to trigger Normalize (:h events)
			'InsertLeave',
			'BufLeave',
			'WinLeave',
			'FocusLost',
			'ExitPre',
		},
		file_pattern = nil, -- File pattern to enable Normalize (nil to any file)
		-- Example:
		-- file_pattern = { '*.md', '*.txt' },
	},

	restore = {
		-- When "Normalize" is about to happen, the plugin saves the state of the input source at the moment.
		-- And the next time you enter Insert-mode, it can automatically restore the saved state.
		-- We call this feature "Restore".

		enable = true, -- Enable Restore?
		on = { -- Events to trigger Restore (:h events)
			'InsertEnter',
			'FocusGained',
		},
		file_pattern = nil, -- File pattern to enable Restore (nil to any file)
		-- Example:
		-- file_pattern = { '*.md', '*.txt' },

		exclude_pattern = '[-a-zA-Z0-9=~+/?!@#$%%^&_(){}%[%];:<>]',
		-- When you switch to Insert-mode, the plugin checks the cursor position at the moment.
		-- And if any of the characters before & after the position match with `exclude_pattern`,
		-- the plugin cancel to restore the input source and leave it as it is.
		-- The default value of `exclude_pattern` is alphanumeric characters with a few exceptions.
		-- Set nil to disable this feature.
	},

	match = {
		-- When you enter Insert-mode, the plugin can detect the language of the characters adjacent to the cursor at the moment.
		-- Then, it can automatically switch the input source to the one that matches the detected language.
		-- We call this feature "Match".
		-- If you enable this feature, we recommend to set `restore.enable` to false.
		-- This feature is disabled by default.

		enable = false, -- Enable Match?
		on = { -- Events to trigger Match (:h events)
			'InsertEnter',
			'FocusGained',
		},
		file_pattern = nil, -- File pattern to enable Match (nil to any file)
		-- Example:
		-- file_pattern = { '*.md', '*.txt' },

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
			-- the plugin can also checks the lines above/below the current line that if they have any characters match `languages`.
			above = 2, -- How meany lines above the current line to check
			below = 1, -- How meany lines below the current line to check
		},
	},

	os = nil, -- 'macos', 'windows', 'linux', or nil to auto-detect
	os_settings = { -- OS-specific settings
		macos = {
			enable = true,
			cmd_get = 'im-select', -- Command to get the current input source
			cmd_set = 'im-select %s', -- Command to set the input source (Use `%s` as a placeholder for the input source)
			normal_input = nil, -- Name of the input source for Normalize (Set nil to auto-detect)
			-- Examples:
			-- normal_input = 'com.apple.keylayout.ABC',
			-- normal_input = 'com.apple.keylayout.US',
			-- normal_input = 'com.apple.keylayout.USExtended',

			lang_inputs = {
				-- The input sources corresponding to `match.languages` for each.
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
}

