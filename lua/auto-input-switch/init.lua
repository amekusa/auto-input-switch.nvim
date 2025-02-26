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
	local defaults = require(ns..'.defaults')
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

	-- #normalize
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
		local valid_context; do
			local get_mode = api.nvim_get_mode
			local s_InsertEnter = 'InsertEnter'
			local s_i = 'i'
			local get_option = api.nvim_get_option_value
			local get_option_arg1 = 'buflisted'
			local get_option_arg2 = {buf = 0}
			valid_context = function(ctx)
				if ctx then
					if ctx.event ~= s_InsertEnter and get_mode().mode ~= s_i then return false end
					get_option_arg2.buf = ctx.buf
				end
				return get_option(get_option_arg1, get_option_arg2)
			end
		end

		local win_get_cursor = api.nvim_win_get_cursor
		local buf_get_lines  = api.nvim_buf_get_lines

		local function max(a, b)
			return a > b and a or b
		end

		-- #restore
		if restore.enable then
			local excludes = restore.exclude_pattern
			M.restore = function(ctx)
				if not active or not valid_context(ctx) then return end

				-- restore input_i that was saved on the last normalize
				if input_i and (input_i ~= input_n) then
					if excludes then -- check if the chars before & after the cursor are alphanumeric
						local row, col = unpack(win_get_cursor(0))
						local line = buf_get_lines(ctx.buf, row - 1, row, true)[1]
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

		-- #match
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
						return item.name, i
					end
				end
			end
			-- main function
			local inputs = oss.lang_inputs
			local lines_above = match.lines.above
			local lines_below = match.lines.below
			local printable = '%S'
			M.match = function(ctx)
				if not active or not valid_context(ctx) then return end

				local found -- language name to find
				local row, col = unpack(win_get_cursor(0)) -- cusor position
				local row_top = max(1, row - lines_above) -- top of the range of rows to search in
				local lines = buf_get_lines(ctx.buf, row_top - 1, row + lines_below, false) -- lines to search in
				local n_lines = #lines
				local cur = row - row_top + 1 -- the index of the current line in `lines`
				local line = lines[cur] -- current line

				if line:find(printable) then -- search in the current line
					found = find_in_map(line:sub(max(1, col - 2), col + 3))
					if found then
						found = inputs[found]
						if found then
							exec(cmd_set:format(found))
						end
					end

				elseif n_lines > 1 then -- current line is empty. search in the lines above/below
					local j, above_done, below_done, found_i
					local n = n_lines - 1
					for i = 1, n do
						if not above_done then
							j = cur - i
							if j > 0 then
								found, found_i = find_in_map(lines[j])
							elseif below_done then
								return
							else
								above_done = true
							end
						end
						if not below_done then
							j = cur + i
							if j <= n_lines then
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
							found = inputs[found]
							if found then
								exec(cmd_set:format(found))
							end
							return
						end
					end
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

