-- auto-input-switch.nvim
--
-- Copyright (c) 2025 Satoshi Soma <noreply@amekusa.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local vim = vim
local api = vim.api

-- lua 5.1 vs 5.2 compatibility
local unpack = unpack or table.unpack

-- levels:
--   - DEBUG
--   - ERROR
--   - INFO
--   - TRACE
--   - WARN
--   - OFF
local function log(msg, level)
	api.nvim_notify('[auto-input-switch] '..msg, vim.log.levels[level or 'INFO'], {})
end

local function trim(str)
	return str:gsub('^%s*(.-)%s*$', '%1')
end

local function detect_os()
	local uname = vim.uv.os_uname().sysname:lower()
	if uname:find('darwin') then
		return 'macos'
	elseif uname:find('windows') then
		return 'windows'
	end
	return 'linux'
end

local M = {}
function M.setup(opts)
	local defaults = {
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
			-- Then, it can automatically switch the input source to the one that matches with the detected language.
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
				-- Languages to match with the characters. Set `enable` to true of the ones you want to use.
				-- `pattern` must be a valid regex string. Use the unicode ranges corresponding to the language.
				-- You can also add your own languages.
				-- If you do, do not forget to add the corresponding inputs to `os_settings[Your OS].lang_inputs` as well.
				Ru = { enable = false, priority = 0, pattern = '[\\u0400-\\u04ff]' },
				Ja = { enable = false, priority = 0, pattern = '[\\u3000-\\u30ff\\uff00-\\uffef\\u4e00-\\u9fff]' },
				Zh = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u4e00-\\u9fff\\u3400-\\u4dbf\\u3100-\\u312f]' },
				Ko = { enable = false, priority = 0, pattern = '[\\u3000-\\u303f\\u1100-\\u11ff\\u3130-\\u318f\\uac00-\\ud7af]' },
			},

			lines = {
				above = 2,
				below = 2,
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
	if opts and type(opts) == 'table'
		then opts = vim.tbl_deep_extend('force', defaults, opts)
		else opts = defaults
	end

	local oss = opts.os_settings[opts.os or detect_os()]
	if not oss.enable then return end

	local cmd_get = oss.cmd_get
	local cmd_set = oss.cmd_set
	local input_n = oss.normal_input
	local input_i

	local normalize = opts.normalize
	local restore   = opts.restore
	local match     = opts.match

	local active = opts.activate
	local async  = opts.async

	-- Returns whether AIS is active or not.
	-- @return boolean
	function M.is_active()
		return active
	end

	-- Sets whether AIS is active or not.
	-- @param boolean x
	function M.set_active(x)
		active = x
	end

	api.nvim_create_user_command('AutoInputSwitch',
		function(cmd)
			local arg = cmd.fargs[1]
			if arg == 'on' then
				active = true
				log('activated')
			elseif arg == 'off' then
				active = false
				log('deactivated')
			else
				log('invalid argument: "'..arg..'"\nIt must be "on" or "off"', 'ERROR')
			end
		end,
		{
			desc = 'Activate/Deactivate auto-input-switch',
			nargs = 1,
			complete = function()
				return {'on', 'off'}
			end
		}
	)

	local exec, exec_get; do
		local split = vim.split
		local split_sep = ' '
		local system = vim.system
		local system_opts = {text = true}
		if async then -- asynchronous implementation
			exec = function(cmd)
				system(split(cmd, split_sep))
			end
			exec_get = function(cmd, handler)
				system(split(cmd, split_sep), system_opts, handler)
			end
		else -- synchronous implementation
			exec = os.execute
			exec_get = function(cmd, handler)
				handler(system(split(cmd, split_sep), system_opts):wait())
			end
		end
	end

	if normalize.enable then
		if not input_n then
			local set_input_n = function(r)
				input_n = trim(r.stdout)
			end
			api.nvim_create_autocmd('InsertEnter', {
				pattern = normalize.file_pattern,
				callback = function()
					exec_get(cmd_get, set_input_n)
					return true -- oneshot
				end
			})
		end

		local save_input = restore.enable and function(r)
			input_i = trim(r.stdout)
		end
		M.normalize = function()
			if not active then return end

			-- save input to input_i before normalize
			if save_input then
				exec_get(cmd_get, save_input)
			end
			-- switch to input_n
			if input_n and (async or input_n ~= input_i) then
				exec(cmd_set:format(input_n))
			end
		end

		api.nvim_create_user_command('AutoInputSwitchNormalize',
			M.normalize, {
				desc = 'Normalize the input source',
				nargs = 0
			}
		)

		if normalize.on then
			api.nvim_create_autocmd(normalize.on, {
				pattern = normalize.file_pattern,
				callback = M.normalize
			})
		end
	end

	if restore.enable or match.enable then
		local check_context; do
			local get_mode = api.nvim_get_mode
			local s_InsertEnter = 'InsertEnter'
			local s_i = 'i'
			local get_option = api.nvim_get_option_value
			local get_option_arg1 = 'buflisted'
			local get_option_arg2 = {buf = 0}
			check_context = function(ctx)
				if ctx then
					if ctx.event ~= s_InsertEnter and get_mode().mode ~= s_i then return false end
					get_option_arg2.buf = ctx.buf
				end
				return get_option(get_option_arg1, get_option_arg2)
			end
		end

		local win_get_cursor = api.nvim_win_get_cursor
		local buf_get_lines  = api.nvim_buf_get_lines

		local function min(a, b)
			return a < b and a or b
		end

		local function max(a, b)
			return a > b and a or b
		end

		if restore.enable then
			local excludes = restore.exclude_pattern
			M.restore = function(ctx)
				if not active or not check_context(ctx) then return end

				-- restore input_i that was saved on the last normalize
				if input_i and (input_i ~= input_n) then
					if excludes then -- check if the chars before & after the cursor are alphanumeric
						local row, col = unpack(win_get_cursor(0))
						local line = buf_get_lines(0, row - 1, row, true)[1]
						if line:sub(col, col + 1):find(excludes) then return end
					end
					exec(cmd_set:format(input_i))
				end
			end

			api.nvim_create_user_command('AutoInputSwitchRestore',
				function() M.restore() end, {
					desc = 'Restore the input source to the state before tha last normalization',
					nargs = 0
				}
			)

			if restore.on then
				api.nvim_create_autocmd(restore.on, {
					pattern = restore.file_pattern,
					callback = M.restore
				})
			end
		end

		if match.enable then

			-- convert `match.languages` to `map`, which is an array sorted by `priority`
			local map = {}; do
				local regex = vim.regex
				for k,v in pairs(match.languages) do
					if v.enable then
						table.insert(map, {
							name = k,
							priority = v.priority,
							pattern = regex(v.pattern),
						})
					end
				end
				table.sort(map, function(a, b)
					return a.priority > b.priority
				end)
			end

			-- returns `name` of the item of `map`, matched with the given string
			local map_len = #map
			local function find_in_map(str)
				for i = 1, map_len do
					local item = map[i]
					if item.pattern:match_str(str) then
						return item.name
					end
				end
			end

			-- main function
			local inputs = oss.lang_inputs
			local lines_above = match.lines.above
			local lines_below = match.lines.below
			local printable = '%S'
			M.match = function(ctx)
				if not active or not check_context(ctx) then return end

				local found -- language name to find
				local buf = ctx.buf
				local row, col = unpack(win_get_cursor(0)) -- cusor position
				local row_top = max(1, row - lines_above) -- top of the range of rows to search in
				local lines = buf_get_lines(buf, row_top - 1, row + lines_below, false) -- lines to search in
				local n_lines = #lines
				local cur = row - row_top + 1 -- the index of the current line in `lines`
				local line = lines[cur] -- current line

				if line:find(printable) then -- search in the current line
					found = find_in_map(line:sub(max(1, col - 2), col + 3))

				elseif n_lines > 2 then -- current line is empty. search in the lines above/below
					local j, above_done, below_done
					for i = 1, n_lines do
						if not above_done then
							j = cur - i
							if j > 0 then
								found = find_in_map(lines[j])
								if found then break end
							elseif below_done then
								break
							else
								above_done = true
							end
						end
						if not below_done then
							j = cur + i
							if j <= n_lines then
								found = find_in_map(lines[j])
								if found then break end
							elseif above_done then
								break
							else
								below_done = true
							end
						end
					end
				end
				if not found then return end
				local input = inputs[found]
				if input then
					exec(cmd_set:format(input))
				end
			end

			api.nvim_create_user_command('AutoInputSwitchMatch',
				function() M.match() end, {
					desc = 'Match the input source with the characters near the cursor',
					nargs = 0
				}
			)

			if match.on then
				api.nvim_create_autocmd(match.on, {
					pattern = match.file_pattern,
					callback = M.match
				})
			end
		end

	end
end

return M

