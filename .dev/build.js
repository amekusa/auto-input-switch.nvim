#!/usr/bin/env node

/**
 * Documentation Generator for Auto-Input-Switch.nvim
 * @author Satoshi Soma (github.com/amekusa)
 */

import {dirname, basename} from 'node:path';
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
			head = padMiddle(head, `*${ns}.${head}*`, docw, 4);
			r = '-'.repeat(docw) + '\n' + head + '\n' + r + '\n\n';
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
		r += '-'.repeat(docw) + '\n' + padMiddle(head, `*${ns}:${k}*`, docw, 4) + '\n';
		if (v.desc && v.desc[lang]) {
			r += indentBlock(v.desc[lang]) + '\n';
		}
		r += '\n';
	}
	return r;
}

function written(file) {
	return err => {
		if (err) throw err;
		console.log('Written:', file);
	};
}

// template helpers
let br = '\n'; // linebreak
let enc = 'utf8'; // encoding
let docw = 78; // document width
let section = br + '='.repeat(docw) + br; // section separator

function indentBlock(str, ind = '\t') {
	return ind + str
		.replaceAll('\n', '\n' + ind)
		.replaceAll(ind + '<', '<');
}

function strWidth(str) {
	let r = 0;
	for (let char of str) {
		let cp = char.codePointAt(0);
		r += (0x00 <= cp && cp < 0x7f) ? 1 : 2
	}
	return r;
}

function padStart(str, width, pad = ' ') {
	let short = width - strWidth(str);
	return short <= 0 ? str : (pad.repeat(Math.floor(short / strWidth(pad))) + str);
}

function padEnd(str, width, pad = ' ') {
	let short = width - strWidth(str);
	return short <= 0 ? str : (str + pad.repeat(Math.floor(short / strWidth(pad))));
}

function padMiddle(start, end, width, margin = 0, pad = ' ') {
	let sw = strWidth(start);
	let ew = strWidth(end);
	let short = width - (sw + ew);
	return start + (
		short <= margin
		? (br + pad.repeat(Math.floor((width - ew) / strWidth(pad))))
		: pad.repeat(Math.floor(short / strWidth(pad)))
	) + end;
}

function h(left, right) {
	return padMiddle(left, right, docw, 4);
}

function sr(str, start, end = null) {
	return start + str + (end || start);
}

function tag(str) {
	return sr(str, '*');
}

function link(str) {
	return sr(str, '|');
}

function codeblock(str, lang = '', ind = '\t') {
	return `>${lang}\n${indentBlock(str, ind)}\n<\n`;
}

function lines(first, ...rest) {
	for (let i = 0; i < rest.length; i++) {
		let next = rest[i];
		first += (first.endsWith(br) || next.startsWith(br)) ? next : (br + next);
	}
	return first;
}

let data;
let logo = `

   ▀█▀██              ▀██▀                  ▄█▀▀▄█
   ▐▌ ██  █ █ ▀█▀ █▀▄  ██  █▀▄ █▀▄ █ █ ▀█▀  ██   █  █ █ █ █ ▀█▀ ▄▀▀ █ █
   █▄▄██  █ █  █  █ █  ██  █ █ █▄█ █ █  █    ▀▀▄▄   █ █ █ █  █  █   █▀█
  ▐▌  ██  ▀▄█  █  ▀▄█  ██  █ █ █   ▀▄█  █   █   ██  ▀▄█▄█ █  █  ▀▄▄ █ █
 ▄█▄ ▄██▄ ━━━━━━━━━━━ ▄██▄ ━━━━━━━━━━━━━━━━ █▀▄▄█▀ ━━━━━━━━━━━━━━━━━━━ ★ NVIM

`;
let footer = `${section}DOCUMENTS

	* About the plugin: |auto-input-switch.nvim|
	*          Options: |auto-input-switch-options|
	*   Default config: |auto-input-switch-defaults|
	*         Commands: |auto-input-switch-commands|

	Note: CTRL-] to jump to the |link| under the cursor.
	      CTRL-T or CTRL-O to jump back.

${section}ドキュメント

	* プラグインについて: |auto-input-switch.nvim.ja|
	*         オプション: |auto-input-switch-options.ja|
	*     デフォルト設定: |auto-input-switch-defaults.ja|
	*           コマンド: |auto-input-switch-commands.ja|

	Note: CTRL-] を押すとカーソル下の |リンク| に飛ぶ。
	      CTRL-T または CTRL-O で戻る。


vim:tw=${docw}:ts=4:noet:ft=help:norl:`;

// options
fs.readFile(base + '/options.yml', enc, (err, data) => {
	if (err) throw err;
	data = yaml.parse(data);
	let dst, out;

	// defaults.lua
	dst = root + '/lua/auto-input-switch/defaults.lua';
	out = toLua(structuredClone(data), {lang: 'en'});
	fs.writeFile(dst, 'return ' + out, enc, written(dst));

	// defaults doc
	dst = root + '/doc/auto-input-switch-defaults.txt';
	out = lines(
		h(tag(basename(dst)), link('auto-input-switch.nvim')),
		logo,
		section,
		h('DEFAULT CONFIG', tag('auto-input-switch-defaults')),
		codeblock(out, 'lua', '  '),
		footer
	);
	fs.writeFile(dst, out, enc, written(dst));

	// defaults doc (ja)
	dst = root + '/doc/auto-input-switch-defaults.ja.txt';
	out = lines(
		h(tag(basename(dst)), link('auto-input-switch.nvim.ja')),
		logo,
		section,
		h('デフォルト設定', tag('auto-input-switch-defaults.ja')),
		codeblock(toLua(structuredClone(data), {lang: 'ja'}), 'lua', '  '),
		footer
	);
	fs.writeFile(dst, out, enc, written(dst));

	// options doc
	dst = root + '/doc/auto-input-switch-options.txt';
	out = lines(
		h(tag(basename(dst)), link('auto-input-switch.nvim')),
		logo,
		section,
		h('OPTIONS', tag('auto-input-switch-options')),
		toDoc(structuredClone(data), {lang: 'en', ns: 'auto-input-switch'}),
		footer
	);
	fs.writeFile(dst, out, enc, written(dst));

	// options doc (ja)
	dst = root + '/doc/auto-input-switch-options.ja.txt';
	out = lines(
		h(tag(basename(dst)), link('auto-input-switch.nvim')),
		logo,
		section,
		h('オプション', tag('auto-input-switch-options.ja')),
		toDoc(structuredClone(data), {lang: 'ja', ns: 'auto-input-switch.ja'}),
		footer
	);
	fs.writeFile(dst, out, enc, written(dst));
});


// commands
fs.readFile(base + '/commands.yml', enc, (err, data) => {
	if (err) throw err;
	data = yaml.parse(data);
	let dst, out;

	// commands doc
	dst = root + '/doc/auto-input-switch-commands.txt';
	out = lines(
		h(tag(basename(dst)), link('auto-input-switch.nvim')),
		logo,
		section,
		h('COMMANDS', tag('auto-input-switch-commands')),
		toCmdDoc(data, {lang: 'en', ns: ''}),
		footer
	);
	fs.writeFile(dst, out, enc, written(dst));

	// commands doc (ja)
	dst = root + '/doc/auto-input-switch-commands.ja.txt';
	out = lines(
		h(tag(basename(dst)), link('auto-input-switch.nvim.ja')),
		logo,
		section,
		h('コマンド', tag('auto-input-switch-commands.ja')),
		toCmdDoc(data, {lang: 'ja', ns: 'ja'}),
		footer
	);
	fs.writeFile(dst, out, enc, written(dst));
});

{ // post-process the main doc
	let dst = root + '/doc/auto-input-switch.txt';
	fs.readFile(dst, enc, (err, data) => {
		if (err) throw err;
		data = data.substring(data.indexOf('\n<\n') + 2).trim(); // remove the header
		let out = lines(
			h(tag(basename(dst)), tag('auto-input-switch.nvim')),
			'日本語: |auto-input-switch.ja.txt|',
			sr(logo, br),
			data
		);
		fs.writeFile(dst, out, enc, written(dst));
	});
}

