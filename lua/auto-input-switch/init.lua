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

local function sanitize_input(input)
	if not input then
		return {nil}
	end
	if type(input) == 'table' then
		return input
	end
	return {input}
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

	local cmd_get = oss.cmd_get
	local cmd_set = oss.cmd_set
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
	local schedule_wrap = vim.schedule_wrap

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

	-- #popup
	local show_popup; if popup then
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

		local updater
		local update_on = {'CursorMoved', 'CursorMovedI'}

		local timer

		local hide_popup = function()
			if timer then
				timer:stop()
				timer:close()
				timer = nil
			end
			if updater then
				api.nvim_del_autocmd(updater)
				updater = nil
			end
			if win_is_valid(win) then
				win_hide(win)
				win = -1
			end
		end

		show_popup = function(str)
			schedule(function()
				hide_popup()

				-- initialize buffer
				str = pad..str..pad
				buf_lines[1] = str
				if not buf_is_valid(buf) then
					buf = buf_create(false, true)
				end
				buf_set_lines(buf, 0, 1, false, buf_lines)

				-- initialize window
				win_opts.width = #str
				win = win_open(buf, false, win_opts)
				whl_scope.win = win
				set_option(whl, whl_group, whl_scope)

				-- position updater
				updater = autocmd(update_on, {
					callback = schedule_wrap(function()
						if win_is_valid(win) then
							win_set_config(win, win_opts)
						end
					end)
				})

				-- timer
				timer = new_timer()
				timer:start(duration, 0, schedule_wrap(hide_popup))
			end)
		end
	end

	-- #normalize
	if normalize then
		if not input_n[1] then
			autocmd('InsertEnter', {
				pattern = normalize.file_pattern or nil,
				callback = function()
					exec_get(cmd_get, function(r)
						input_n[1] = trim(r.stdout)
					end)
					return true -- oneshot
				end
			})
		end

		local popup_text = popup and normalize.popup
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
				exec(cmd_set:format(input_n[2] or input_n[1]))
				if popup_text then
					show_popup(popup_text)
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
							exec(cmd_set:format(input[2] or input[1]))
							if popup then
								show_popup(found)
							end
						end
					end

				elseif n_lines > 1 then -- current line is empty. search in the lines above/below
					local j, above_done, below_done, found_i
					for i = 1, n_lines do
						if not above_done then
							j = cur - i
							if j > 0 and not (exclude and exclude:match_str(lines[j])) then
								found, found_i = find_in_map(lines[j])
							elseif below_done then
								return
							else
								above_done = true
							end
						end
						if not below_done then
							j = cur + i
							if j <= n_lines and not (exclude and exclude:match_str(lines[j])) then
								if found then -- already found in the line above
									local _found, _found_i = find_in_map(lines[j])
									if _found and _found_i < found_i then -- more prioritized lang found
										found = _found
									end
								else
									found = find_in_map(lines[j])
								end
							elseif above_done then
								return
							else
								below_done = true
							end
						end
						if found then
							local input = lang_inputs[found]
							if input then
								matched = true; schedule(reset_matched)
								exec(cmd_set:format(input[2] or input[1]))
								if popup then
									show_popup(found)
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
			local langs; if popup then
				langs = {}
				for k,v in pairs(lang_inputs) do
					if v[1] then
						langs[v[1]] = k
					end
				end
			end

			local excludes = restore.exclude_pattern
			M.restore = function(c)
				if not active or matched or not valid_context(c) then return end

				-- restore input_i that was saved on the last normalize
				if input_i and (input_i ~= input_n[1]) then
					if excludes then -- check if the chars before & after the cursor are alphanumeric
						local row, col = unpack(win_get_cursor(0))
						local line = buf_get_lines(c and c.buf or 0, row - 1, row, true)[1]
						if line:sub(col, col + 1):find(excludes) then return end
					end
					exec(cmd_set:format(input_i))
					if popup then
						local lang = langs[input_i]
						if lang then
							show_popup(lang)
						end
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

