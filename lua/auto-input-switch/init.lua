-- AUTO-INPUT-SWITCH.nvim
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

local exec     = os.execute
local exec_get = vim.fn.system

local M = {}
function M.setup(opts)
	local defaults = {
		activate = true,
		normalize = {
			enable = true,
			on = {
				'InsertLeave',
				'FocusGained',
				'FocusLost',
			},
		},
		restore = {
			enable = true,
			on = {
				'InsertEnter'
			},
			file_pattern = nil,
			exclude_pattern = '[-a-zA-Z0-9=~+/?!@#$%%^&_(){}%[%];:<>]',
		},
		os = nil, -- macos/windows/linux or nil to auto-detect
		os_settings = {
			macos = {
				enable = true,
				cmd_get = 'im-select', -- command to get the current input-source
				cmd_set = 'im-select %s', -- command to set the input-source (use `%s` as a placeholder)
				normal_input = nil, -- auto
				-- normal_input = 'com.apple.keylayout.ABC',
				-- normal_input = 'com.apple.keylayout.US',
				-- normal_input = 'com.apple.keylayout.USExtended',
			},
			windows = {
				enable = true,
				cmd_get = 'im-select.exe',
				cmd_set = 'im-select.exe %s',
				normal_input = nil, -- auto
			},
			linux = {
				enable = true,
				cmd_get = 'ibus engine',
				cmd_set = 'ibus engine %s',
				normal_input = nil, -- auto
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

	local active = opts.activate

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
			nargs = 1,
			complete = function()
				return {'on', 'off'}
			end
		}
	)

	if normalize.enable then
		if not input_n then
			api.nvim_create_autocmd('InsertEnter', {
				callback = function()
					input_n = trim(exec_get(cmd_get))
					return true -- oneshot
				end
			})
		end

		local restore_enable = restore.enable
		local function fn_normalize()
			if not active then return end

			-- save input to input_i before normalize
			if restore_enable
				then input_i = trim(exec_get(cmd_get))
				else input_i = nil
			end
			-- switch to input_n
			if input_n and (input_n ~= input_i) then
				exec(cmd_set:format(input_n))
			end
		end

		api.nvim_create_autocmd(normalize.on, {
			callback = fn_normalize
		})
	end

	if restore.enable then
		local buf_is_listed; do
			local get_option = api.nvim_get_option_value
			local get_option_arg1 = 'buflisted'
			local get_option_arg2 = {buf = 0}
			buf_is_listed = function(buf)
				get_option_arg2.buf = buf
				return get_option(get_option_arg1, get_option_arg2)
			end
		end

		local excludes = restore.exclude_pattern
		local win_get_cursor = api.nvim_win_get_cursor
		local buf_get_lines  = api.nvim_buf_get_lines
		local function fn_restore(ctx)
			if not active or not buf_is_listed(ctx.buf) then return end

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

		api.nvim_create_autocmd(restore.on, {
			pattern = restore.file_pattern,
			callback = fn_restore
		})
	end

end

return M

