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

local ns = (...)
local vim = vim
local api = vim.api
local regex = vim.regex

-- lua 5.1 vs 5.2 compatibility
local unpack = unpack or table.unpack

-- levels:
--   - DEBUG
--   - ERROR
--   - INFO
--   - TRACE
--   - WARN
--   - OFF
local function notify(msg, level)
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
	local defaults = require(ns..'.defaults')
	if opts and type(opts) == 'table'
		then opts = vim.tbl_deep_extend('force', defaults, opts)
		else opts = defaults
	end

	local oss = opts.os_settings[opts.os or detect_os()]
	if not oss.enable then return end

	local log; if opts.log then
		local out = vim.fn.stdpath('log')..'/auto-input-switch.log'
		local f = io.open(out, 'w')
		if f then
			f:write('# auto-input-switch.nvim log\n# Initialized at '..os.date('%Y-%m-%d %X')..'\n\n')
			f:close()

			log = function(...)
				local args = {...}
				f = io.open(out, 'a+')
				if not f then
					notify('cannot open the log file: '..out, 'WARN')
					return
				end
				local msg = '['..os.date('%Y-%m-%d %X')..']'
				local inspect = vim.inspect
				local item, t
				for i = 1, #args do
					item = args[i]
					t = type(item)
					if t ~= 'string' then
						if t == 'table'
							then item = inspect(item)
							else item = t..'('..item..')'
						end
					end
					msg = msg..' '..item
				end
				f:write(msg..'\n')
				f:close()
			end
		else
			notify('cannot open the log file: '..out, 'WARN')
		end
	end

	local cmd_get = oss.cmd_get
	local cmd_set = oss.cmd_set

	----
	-- input format: {
	--   [1] = <InputName>,
	--   [2] = <inputNameAlt>,
	--   [3] = <CmdSetFormatted>,
	--   cmd_set = <CmdSet>,
	-- }
	local function sanitize_input(input)
		if not input then
			return {false, false, ''}
		end
		if type(input) == 'table' then
			input[3] = (input.cmd_set or cmd_set or ''):format(input[2] or input[1] or '')
			return input
		end
		return {input, false, cmd_set:format(input)}
	end

	local input_n = sanitize_input(oss.normal_input)
	local input_i

	local popup     = opts.popup.enable     and opts.popup
	local normalize = opts.normalize.enable and opts.normalize
	local restore   = opts.restore.enable   and opts.restore
	local match     = opts.match.enable     and opts.match

	local active = opts.activate
	local async  = opts.async
	local prefix = opts.prefix

	local autocmd = api.nvim_create_autocmd
	local usercmd = api.nvim_create_user_command

	local schedule      = vim.schedule

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

	usercmd(prefix,
		function(cmd)
			local arg = cmd.fargs[1]
			if arg == 'on' then
				active = true
				notify('activated')
			elseif arg == 'off' then
				active = false
				notify('deactivated')
			else
				notify('invalid argument: "'..arg..'"\nIt must be "on" or "off"', 'ERROR')
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

	-- functions to handle shell-commands
	local exec, exec_get; do
		local split = vim.split
		local split_sep = ' '
		local system = vim.system
		local system_opts = {text = true}

		local log_pre, log_post; if log then
			log_pre = function(cmd)
				log('start exec:', cmd)
				return cmd
			end
			log_post = function(cmd, r)
				log(' done exec:', cmd, '\nresult:', r)
				return r
			end
		end
		if async then -- asynchronous implementation
			if log then -- with logging
				exec = function(cmd)
					system(split(log_pre(cmd), split_sep), system_opts, function(r)
						log_post(cmd, r)
					end)
				end
				exec_get = function(cmd, handler)
					system(split(log_pre(cmd), split_sep), system_opts, function(r)
						handler(log_post(cmd, r))
					end)
				end
			else -- without logging
				exec = function(cmd)
					system(split(cmd, split_sep))
				end
				exec_get = function(cmd, handler)
					system(split(cmd, split_sep), system_opts, handler)
				end
			end
		else -- synchronous implementation
			if log then -- with logging
				exec = function(cmd)
					log_post(cmd, system(split(log_pre(cmd), split_sep)):wait())
				end
				exec_get = function(cmd, handler)
					handler(log_post(cmd, system(split(log_pre(cmd), split_sep), system_opts):wait()))
				end
			else -- without logging
				exec = os.execute
				exec_get = function(cmd, handler)
					handler(system(split(cmd, split_sep), system_opts):wait())
				end
			end
		end
	end

	-- #popup
	local show_popup; if popup then
		local del_autocmd    = api.nvim_del_autocmd
		local buf_is_valid   = api.nvim_buf_is_valid
		local buf_create     = api.nvim_create_buf
		local buf_set_lines  = api.nvim_buf_set_lines
		local win_is_valid   = api.nvim_win_is_valid
		local win_open       = api.nvim_open_win
		local win_hide       = api.nvim_win_hide
		local win_set_config = api.nvim_win_set_config
		local set_option     = api.nvim_set_option_value
		local new_timer      = vim.uv.new_timer

		local duration = popup.duration
		local pad      = popup.pad and ' '

		local state = 0
		-- 0: IDLE
		-- 1: ACTIVATING
		-- 2: ACTIVE
		-- 3: DEACTIVATING

		local buf = -1
		local buf_lines = {''}

		local win = -1
		local win_opts = {
			relative = popup.relative,
			row = popup.row,
			col = popup.col,
			anchor = popup.anchor,
			border = popup.border,
			zindex = popup.zindex,
			height = 1,
			style = 'minimal',
			focusable = false,
		}

		local whl = 'winhighlight'
		local whl_group = 'NormalFloat:'..popup.hl_group
		local whl_scope = {win = nil}

		local updater = -1
		local updater_ev = {'CursorMoved', 'CursorMovedI', 'WinScrolled'}
		local updater_opts = {
			callback = function()
				if state == 2 and win_is_valid(win) then -- state == ACTIVE
					win_set_config(win, win_opts)
				end
			end
		}

		local timer
		local deactivate = function()
			state = 0 -- state >> IDLE
			if updater >= 0 then
				del_autocmd(updater)
				updater = -1
			end
			if win_is_valid(win) then
				win_hide(win)
				win = -1
			end
		end
		local on_timeout = function()
			state = 3 -- state >> DEACTIVATING
			timer:stop()
			timer:close()
			schedule(deactivate)
		end

		local str, len
		local activate = function()
			state = 2 -- state >> ACTIVE

			-- initialize buffer
			buf_lines[1] = str
			if not buf_is_valid(buf) then
				buf = buf_create(false, true)
			end
			buf_set_lines(buf, 0, 1, false, buf_lines)

			-- initialize window
			if win_is_valid(win) then
				win_hide(win)
			end
			win_opts.width = len
			win = win_open(buf, false, win_opts)
			whl_scope.win = win
			set_option(whl, whl_group, whl_scope)

			-- position updater
			if updater < 0 then
				updater = autocmd(updater_ev, updater_opts)
			end
		end
		show_popup = function(label)
			if pad then
				str = pad..label[1]..pad
				len = label[2] + 2
			else
				str = label[1]
				len = label[2]
			end
			if state == 1 then return end -- state == ACTIVATING
			if state == 2 then -- state == ACTIVE
				timer:stop()
				timer:close()
			end
			state = 1 -- state >> ACTIVATING
			timer = new_timer()
			timer:start(duration, 0, on_timeout)
			schedule(activate)
		end
	end

	-- #normalize
	if normalize then

		--- auto-detect normal-input
		if not input_n[1] then
			autocmd('InsertEnter', {
				pattern = normalize.file_pattern or nil,
				callback = function()
					exec_get(cmd_get, function(r)
						input_n[1] = trim(r.stdout)
						sanitize_input(input_n)
					end)
					return true -- oneshot
				end
			})
		end

		local label = popup and popup.labels.normal_input
		local save_input = restore and function(r)
			input_i = trim(r.stdout)
		end
		M.normalize = function()
			if not active then return end

			-- save input to input_i before normalize
			if save_input then
				exec_get(cmd_get, save_input)
			end
			-- switch to input_n
			if input_n[1] and (async or input_n[1] ~= input_i) then
				exec(input_n[3])
				if label then
					if type(label) ~= 'table' then
						if type(label) == 'string'
							then label = {label, #label}
							else label = {'A', 1}
						end
					end
					show_popup(label)
				end
			end
		end

		usercmd(prefix..'Normalize',
			M.normalize, {
				desc = 'Normalize the input source',
				nargs = 0
			}
		)

		if normalize.on then
			autocmd(normalize.on, {
				pattern = normalize.file_pattern or nil,
				callback = M.normalize
			})
		end
	end

	if restore or match then

		local valid_context; do
			local event = 'InsertEnter'
			local mode  = 'i'
			local get_mode = api.nvim_get_mode
			local get_option = api.nvim_get_option_value
			local get_option_key = 'buflisted'
			local get_option_scope = {buf = 0}
			valid_context = function(c)
				if c then
					if c.event ~= event and get_mode().mode ~= mode then
						return false
					end
					get_option_scope.buf = c.buf
				end
				return get_option(get_option_key, get_option_scope)
			end
		end

		local max = function(a, b)
			return a > b and a or b
		end

		local win_get_cursor = api.nvim_win_get_cursor
		local buf_get_lines  = api.nvim_buf_get_lines

		local lang_labels = popup and popup.labels.lang_inputs

		-- sanitize entries of lang_inputs
		local lang_inputs = {}
		for k,v in pairs(oss.lang_inputs) do
			lang_inputs[k] = sanitize_input(v)
		end

		-- flag for prevending `restore` from executing after `match` in the same frame
		local matched = false

		-- #match
		if match then

			-- convert `match.languages` to `map`, which is an array sorted by `priority`
			local map = {}; do
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
						return item.name, i
					end
				end
			end

			-- schedule this:
			local function reset_matched()
				matched = false
			end

			local lines_above = match.lines.above
			local lines_below = match.lines.below
			local exclude = match.lines.exclude_pattern and regex(match.lines.exclude_pattern)
			local printable = '%S'
			M.match = function(c)
				if not active or not valid_context(c) then return end

				local found -- language name to find
				local row, col = unpack(win_get_cursor(0)) -- cusor position
				local row_top = max(1, row - lines_above) -- top of the range of rows to search in
				local lines = buf_get_lines(c and c.buf or 0, row_top - 1, row + lines_below, false) -- lines to search in
				local n_lines = #lines
				local cur = row - row_top + 1 -- the index of the current line in `lines`
				local line = lines[cur] -- current line

				if line:find(printable) then -- search in the current line
					found = find_in_map(line:sub(max(1, col - 2), col + 3))
					if found then
						local input = lang_inputs[found]
						if input then
							matched = true; schedule(reset_matched)
							exec(input[3])
							if popup then
								local label = lang_labels[found]
								if type(label) ~= 'table' then
									if type(label) == 'string'
										then label = {label, #label}
										else label = {found, #found}
									end
									lang_labels[found] = label
								end
								show_popup(label)
							end
						end
					end

				elseif n_lines > 1 then -- current line is empty. search in the lines above/below
					local above_done, below_done, found_i
					for i = 1, n_lines do

						-- search up
						if above_done then
							if below_done then return end
						else
							line = lines[cur - i]
							if line then
								if line:find(printable) then -- not an empty line
									above_done = true -- found or not, no more searching up
									if not (exclude and exclude:match_str(line)) then
										found, found_i = find_in_map(line)
									end
								end
							else
								above_done = true -- no more lines to search in
							end
						end

						-- search down
						if not below_done then
							line = lines[cur + i]
							if line then
								if line:find(printable) then -- not an empty line
									below_done = true -- found or not, no more searching down
									if not (exclude and exclude:match_str(line)) then
										if found then -- already found in the lines above
											local _found, _found_i = find_in_map(line)
											if _found and _found_i < found_i then -- more prioritized language is found
												found = _found
											end
										else
											found = find_in_map(line)
										end
									end
								end
							else
								below_done = true -- no more lines to search in
							end
						end

						if found then
							local input = lang_inputs[found]
							if input then
								matched = true; schedule(reset_matched)
								exec(input[3])
								if popup then
									local label = lang_labels[found]
									if type(label) ~= 'table' then
										if type(label) == 'string'
											then label = {label, #label}
											else label = {found, #found}
										end
										lang_labels[found] = label
									end
									show_popup(label)
								end
							end
							return
						end
					end
				end
			end

			usercmd(prefix..'Match',
				function() M.match() end, {
					desc = 'Match the input source with the characters near the cursor',
					nargs = 0
				}
			)

			if match.on then
				autocmd(match.on, {
					pattern = match.file_pattern or nil,
					callback = M.match
				})
			end
		end

		-- #restore
		if restore then

			-- create a reverse-lookup table of lang_inputs
			local lang_lookup; if popup then
				lang_lookup = {}
				for k,v in pairs(lang_inputs) do
					if v[1] then
						lang_lookup[v[1]] = k
					end
				end
			end

			local exclude = restore.exclude_pattern
			M.restore = function(c)
				if not active or matched or not valid_context(c) then return end

				-- restore input_i that was saved on the last normalize
				if input_i and (input_i ~= input_n[1]) then
					if exclude then -- check if the chars before & after the cursor are alphanumeric
						local row, col = unpack(win_get_cursor(0))
						local line = buf_get_lines(c and c.buf or 0, row - 1, row, true)[1]
						if line:sub(col, col + 1):find(exclude) then return end
					end
					local lang = lang_lookup[input_i]
					if lang then
						local input = lang_inputs[lang]
						exec(input[3])
						if popup then
							local label = lang_labels[lang]
							if type(label) ~= 'table' then
								if type(label) == 'string'
									then label = {label, #label}
									else label = {lang, #lang}
								end
								lang_labels[lang] = label
							end
							show_popup(label)
						end
					else -- unknown input
						exec(cmd_set:format(input_i))
					end
				end
			end

			usercmd(prefix..'Restore',
				function() M.restore() end, {
					desc = 'Restore the input source to the state before tha last normalization',
					nargs = 0
				}
			)

			if restore.on then
				autocmd(restore.on, {
					pattern = restore.file_pattern or nil,
					callback = M.restore
				})
			end
		end

	end
end

return M

