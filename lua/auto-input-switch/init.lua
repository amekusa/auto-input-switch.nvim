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

-- levels:
--   - DEBUG
--   - ERROR
--   - INFO
--   - TRACE
--   - WARN
--   - OFF
function log(msg, level)
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
		features = {
			normalize_on_focus            = true,
			normalize_on_leave_insertmode = true,
			restore_on_enter_insertmode   = true,
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

	local features = opts.features

	api.nvim_create_user_command('AutoInputSwitch',
		function(cmd)
			local arg = cmd.fargs[1]
			if arg == 'on' then
				opts.activate = true
				log('activated')
			elseif arg == 'off' then
				opts.activate = false
				log('deactivated')
			else
				log('invalid argument: on | off', 'ERROR')
			end
		end, {
			nargs = 1,
			complete = function()
				return {'on', 'off'}
			end
		}
	)

	api.nvim_create_autocmd('FocusGained', {
		callback = function()
			if not opts.activate then return end

			-- switch to input_n
			if features.normalize_on_focus and input_n and (input_n ~= input_i) then
				exec(cmd_set:format(input_n))
			end
		end
	})

	api.nvim_create_autocmd('InsertEnter', {
		callback = function()
			if not opts.activate then return end

			-- save input to input_n
			if (not input_n) and features.normalize_on_leave_insertmode then
				input_n = trim(exec_get(cmd_get))
			end
			-- switch to input_i
			if features.restore_on_enter_insertmode and input_i and (input_i ~= input_n) then
				exec(cmd_set:format(input_i))
			end
		end
	})

	api.nvim_create_autocmd('InsertLeave', {
		callback = function()
			if not opts.activate then return end

			-- save input to input_i
			if features.restore_on_enter_insertmode
				then input_i = trim(exec_get(cmd_get))
				else input_i = nil
			end
			-- switch to input_n
			if features.normalize_on_leave_insertmode and input_n and (input_n ~= input_i) then
				exec(cmd_set:format(input_n))
			end
		end
	})

end

return M

