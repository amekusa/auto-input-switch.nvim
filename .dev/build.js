#!/usr/bin/env node

/**
 * Documentation Generator for Auto-Input-Switch.nvim
 * @author Satoshi Soma (github.com/amekusa)
 */

import {dirname} from 'node:path';
import fs from 'node:fs';
import yaml from 'yaml';

let base = import.meta.dirname;
let root = dirname(base); // project root

/**
 * Converts the given value into a Lua expression.
 * @author Satoshi Soma (github.com/amekusa)
 *
 * @param {any} data -
 * @param {object} opts - Options
 * @param {string} opts.tab -
 * @param {string} opts.lang -
 * @param {object} c - Context
 * @param {number} c.depth -
 * @param {string} c.key -
 * @param {string} c.comment -
 * @return {string} a Lua expression
 */
function toLua(data, opts, c = {}) {
	let {
		tab = '  ',
		lang = 'en',
	} = opts;

	let {
		depth = 0,
		key = null,
		comment = '',
	} = c;

	let ind = tab.repeat(depth);
	let r = ind;
	if (key) r += `${key} = `;

	if (comment) { // convert into Lua comments
		comment = comment
			.replaceAll(/`'(.+?)'`/g, "'$1'") // `'something'` to 'something'
			.replaceAll(/\s?>lua\n/g, '\n')   // remove '>lua'
			.replaceAll(/\n<(\n|$)/g, '\n$1') // remove '<'
			.trim();

		let lines = comment.split(/\r?\n/);
		comment = ` -- ${lines[0]}`;
		if (lines.length > 1) { // multi-line comments
			for (let i = 1; i < lines.length; i++) {
				comment += `\n${ind}${tab}-- ${lines[i]}`;
			}
			comment += '\n'; // add a blank line for legibility
		}
	}

	switch (typeof data) {
	case 'object':
		if (!data) {
			r += 'nil';
			break;
		}
		if ('__desc' in data) { // special key: __desc
			c = {depth, key, comment: data.__desc[lang] || ''};
			delete data.__desc;
			return toLua(data, opts, c);
		}
		if ('__default' in data) { // special key: __default
			return toLua(data.__default, opts, c);
		}
		r += '{' + comment + '\n';
		comment = '';
		c = {depth: depth + 1};
		if (Array.isArray(data)) {
			for (let i = 0; i < data.length; i++) {
				r += toLua(data[i], opts, c) + '\n';
			}
		} else {
			let keys = Object.keys(data);
			for (let i = 0; i < keys.length; i++) {
				let k = keys[i];
				let v = data[k];
				c.key = k;
				r += toLua(v, opts, c) + '\n';
			}
		}
		r += ind + '}';
		break;

	case 'string':
		// special tag: <!CODE>
		let m = data.match(/^\s*<!CODE>(.*)$/); if (m) {
			r += m[1];
			break;
		}
		r += `'${data}'`;
		break;

	case 'boolean':
		r += data ? 'true' : 'false';
		break;

	default:
		r += `${data}`;
	}

	if (depth) r += ',';
	r += comment;
	return r;
}

/**
 * Converts the given object into a Vim help doc.
 * @author Satoshi Soma (github.com/amekusa)
 *
 * @param {object} data -
 * @param {object} opts - Options
 * @param {string} opts.ns - Namespace
 * @param {string} opts.lang - Language
 * @param {string[]} stack - Object key stack
 * @return {string} a Vim help doc
 */
function toDoc(data, opts, stack = null) {
	if (!data || typeof data != 'object') return '';

	let {
		ns = '',
		lang = 'en',
	} = opts;

	let r = '';

	if (stack) {
		if ('__default' in data) {
			r = toLua(data.__default, {lang});
			if (r.includes('\n')) r = '- default: >lua\n' + r + '\n<\n';
			else                  r = '- default: `' + r + '`\n';
			delete data.__default;
		}
		if ('__desc' in data) {
			if (data.__desc[lang]) r += data.__desc[lang];
			delete data.__desc;
		}
		if (r) { // register section
			r = indentBlock(r);
			// section header
			let head = stack.join('.');
			head = padMiddle(head, `*${ns}.${head}*`, 78, 4);
			r = '-'.repeat(78) + '\n' + head + '\n' + r + '\n\n';
		}
	}

	let keys = Object.keys(data);
	for (let i = 0; i < keys.length; i++) {
		let k = keys[i];
		let v = data[k];
		r += toDoc(v, opts, stack ? [...stack, k] : [k]);
	}
	return r;
}

function padMiddle(start, end, length, margin = 0, pad = ' ') {
	let nPad = length - (start.length + end.length);
	return start + (nPad < margin ? ('\n' + end.padStart(length, pad)) : (pad.repeat(nPad) + end));
}

function toCmdDoc(data, opts) {
	let {
		ns = '',
		lang = 'en',
	} = opts;

	let r = '';

	let keys = Object.keys(data);
	for (let i = 0; i < keys.length; i++) {
		let k = keys[i]; // command name
		let v = data[k];
		let head = ':' + k;
		if (v.args) head += ' ' + v.args;
		r += '-'.repeat(78) + '\n' + padMiddle(head, `*${ns}:${k}*`, 78, 4) + '\n';
		if (v.desc && v.desc[lang]) {
			r += indentBlock(v.desc[lang]) + '\n';
		}
		r += '\n';
	}
	return r;
}

function indentBlock(str, ind = '\t') {
	return ind + str
		.replaceAll('\n', '\n' + ind)
		.replaceAll(ind + '<', '<');
}

function written(file) {
	return err => {
		if (err) throw err;
		console.log('Written:', file);
	};
}

let dst, out, data;
data = yaml.parse(fs.readFileSync(base + '/options.yml', 'utf8'));
let logo = `

  ▀█▀██              ▀██▀                 ██▀▀▄█
  ▐▌ ██  █ █ ▀█▀ █▀▄  ██  █▀▄ █▀▄ █ █ ▀█▀ ██   █ █ █ █ █ ▀█▀ ▄▀▀ █ █
  █▄▄██  █ █  █  █ █  ██  █ █ █▄█ █ █  █   ▀▀▄▄  █ █ █ █  █  █   █▀█
 ▐▌  ██  ▀▄█  █  ▀▄█  ██  █ █ █   ▀▄█  █  █   ██ ▀▄█▄█ █  █  ▀▄▄ █ █
▄█▄ ▄██▄ ━━━━━━━━━━━ ▄██▄ ━━━━━━━━━━━━━━━ █▀▄▄██ ━━━━━━━━━━━━━━━━━━ ★ NVIM

`;
let footer = `
==============================================================================
DOCUMENTS

	* About the plugin: |auto-input-switch.nvim|
	*          Options: |auto-input-switch-options|
	*   Default config: |auto-input-switch-defaults|
	*         Commands: |auto-input-switch-commands|

	Note: CTRL-] to jump to the |link| under the cursor.
	      CTRL-T or CTRL-O to jump back.


==============================================================================
ドキュメント

	* プラグインについて: |auto-input-switch.nvim.ja|
	*         オプション: |auto-input-switch-options.ja|
	*     デフォルト設定: |auto-input-switch-defaults.ja|
	*           コマンド: |auto-input-switch-commands.ja|

	Note: CTRL-] を押すとカーソル下の |リンク| に飛ぶ。
	      CTRL-T または CTRL-O で戻る。


vim:tw=78:ts=4:noet:ft=help:norl:`;


// --- defaults.lua ---
dst = root + '/lua/auto-input-switch/defaults.lua';
out = toLua(structuredClone(data), {lang: 'en'});
fs.writeFile(dst, 'return ' + out, 'utf8', written(dst));


// --- defaults doc ---
dst = root + '/doc/auto-input-switch-defaults.txt';
out = `*auto-input-switch-defaults.txt*                      |auto-input-switch.nvim|
${logo}
==============================================================================
DEFAULT CONFIG                                    *auto-input-switch-defaults*

>lua
${indentBlock(out, '  ')}
<` + footer;
fs.writeFile(dst, out, 'utf8', written(dst));


// --- defaults doc (ja) ---
dst = root + '/doc/auto-input-switch-defaults.ja.txt';
out = `*auto-input-switch-defaults.ja.txt*                |auto-input-switch.nvim.ja|
${logo}
==============================================================================
デフォルト設定                                 *auto-input-switch-defaults.ja*

>lua
${indentBlock(toLua(structuredClone(data), {lang: 'ja'}), '  ')}
<` + footer;
fs.writeFile(dst, out, 'utf8', written(dst));


// --- options doc ---
dst = root + '/doc/auto-input-switch-options.txt';
out = `*auto-input-switch-options.txt*                       |auto-input-switch.nvim|
${logo}
==============================================================================
OPTIONS                                            *auto-input-switch-options*

` + toDoc(structuredClone(data), {lang: 'en', ns: 'auto-input-switch'}) + footer;
fs.writeFile(dst, out, 'utf8', written(dst));


// --- options doc (ja) ---
dst = root + '/doc/auto-input-switch-options.ja.txt';
out = `*auto-input-switch-options.ja.txt*                 |auto-input-switch.nvim.ja|
${logo}
==============================================================================
オプション                                      *auto-input-switch-options.ja*

` + toDoc(structuredClone(data), {lang: 'ja', ns: 'auto-input-switch.ja'}) + footer;
fs.writeFile(dst, out, 'utf8', written(dst));


// --- commands doc ---
data = yaml.parse(fs.readFileSync(base + '/commands.yml', 'utf8'));
dst = root + '/doc/auto-input-switch-commands.txt';
out = `*auto-input-switch-commands.txt*                      |auto-input-switch.nvim|
${logo}
==============================================================================
COMMANDS                                          *auto-input-switch-commands*

` + toCmdDoc(data, {lang: 'en', ns: ''}) + footer;
fs.writeFile(dst, out, 'utf8', written(dst));


// --- commands doc (ja) ---
dst = root + '/doc/auto-input-switch-commands.ja.txt';
out = `*auto-input-switch-commands.ja.txt*                |auto-input-switch.nvim.ja|
${logo}
==============================================================================
コマンド                                       *auto-input-switch-commands.ja*

` + toCmdDoc(data, {lang: 'ja', ns: 'ja'}) + footer;
fs.writeFile(dst, out, 'utf8', written(dst));

