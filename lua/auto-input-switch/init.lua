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
		features = {
			normalize_on_gain_focus       = {enable = true},
			normalize_on_lose_focus       = {enable = true},
			normalize_on_leave_insertmode = {enable = true},
			restore_on_enter_insertmode   = {
				enable = true,
				condition = nil,
			},
		},
		normalize = {
			exclude_insertmode = true,
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

	local active = opts.activate
	local features = opts.features
	local restore_on_enter_insertmode = features.restore_on_enter_insertmode.enable

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
				log('invalid argument: on | off', 'ERROR')
			end
		end,
		{
			nargs = 1,
			complete = function()
				return {'on', 'off'}
			end
		}
	)

	do
		local condition = features.restore_on_enter_insertmode.condition
		if not condition then
			local get_option = vim.api.nvim_get_option_value
			local get_option_arg1 = 'buftype'
			local get_option_arg2 = {buf = false}
			condition = function(ctx)
				get_option_arg2.buf = ctx.buf
				return get_option(get_option_arg1, get_option_arg2):len() == 0
				--   NOTE: Regular buffer has buftype empty
			end
		end

		api.nvim_create_autocmd('InsertEnter', {
			callback = function(ctx)
				if (not active) or (not condition(ctx)) then return end

				-- save input to input_n
				if not input_n then
					input_n = trim(exec_get(cmd_get))
				end
				-- restore input_i that was saved on the last normalize
				if restore_on_enter_insertmode and input_i and (input_i ~= input_n) then
					exec(cmd_set:format(input_i))
				end
			end
		})
	end

	do
		local exclude_insertmode = opts.normalize.exclude_insertmode
		local get_mode = api.nvim_get_mode
		local s_insertleave = 'InsertLeave'
		local s_i = 'i'
		local function normalize(ctx)
			if (not active) or (exclude_insertmode and (ctx.event ~= s_insertleave) and (get_mode().mode == s_i)) then return end

			-- save input to input_i before normalize
			if restore_on_enter_insertmode
				then input_i = trim(exec_get(cmd_get))
				else input_i = nil
			end
			-- switch to input_n
			if input_n and (input_n ~= input_i) then
				exec(cmd_set:format(input_n))
			end
		end

		local normalize_on = {}
		if features.normalize_on_leave_insertmode.enable then
			table.insert(normalize_on, 'InsertLeave')
		end
		if features.normalize_on_gain_focus.enable then
			table.insert(normalize_on, 'FocusGained')
		end
		if features.normalize_on_lose_focus.enable then
			table.insert(normalize_on, 'FocusLost')
		end
		api.nvim_create_autocmd(normalize_on, {callback = normalize})
	end

end

return M

