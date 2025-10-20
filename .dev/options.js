#!/usr/bin/env node

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
			let tag = `*${ns}.${head}*`;
			let pad = 78 - (head.length + tag.length);
			head += pad < 4 ? ('\n' + tag.padStart(78, ' ')) : (' '.repeat(pad) + tag);
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

function indentBlock(str, ind = '\t') {
	str = str.replaceAll('\n', '\n' + ind);
	str = str.replaceAll(ind + '<', '<');
	str = ind + str;
	return str;
}

function written(file) {
	return err => {
		if (err) throw err;
		console.log('Written:', file);
	};
}

let options = yaml.parse(fs.readFileSync(base + '/options.yml', 'utf8'));
let dst, out;
let footer = `
==============================================================================
OTHER DOCUMENTS

	- About the plugin: |auto-input-switch.nvim|
	-          Options: |auto-input-switch-options|
	-   Default config: |auto-input-switch-defaults|


vim:tw=78:ts=4:noet:ft=help:norl:`;


// --- defaults.lua ---
dst = root + '/lua/auto-input-switch/defaults.lua';
out = toLua(structuredClone(options), {lang: 'en'});
fs.writeFile(dst, 'return ' + out, 'utf8', written(dst));


// --- defaults doc ---
dst = root + '/doc/auto-input-switch-defaults.txt';
out = `*auto-input-switch-defaults.txt* - Defaults for |auto-input-switch.nvim|

==============================================================================
DEFAULTS                                          *auto-input-switch-defaults*

>lua
${indentBlock(out, '  ')}
<` + footer;
fs.writeFile(dst, out, 'utf8', written(dst));


// --- defaults.ja.lua ---
dst = root + '/lua/auto-input-switch/defaults.ja.lua';
out = toLua(structuredClone(options), {lang: 'ja'});
fs.writeFile(dst, 'return ' + out, 'utf8', written(dst));


// --- options doc ---
dst = root + '/doc/auto-input-switch-options.txt';
out = `*auto-input-switch-options.txt* - Options for |auto-input-switch.nvim|

==============================================================================
OPTIONS                                            *auto-input-switch-options*

	Note: CTRL-] to jump to the |link| under the cursor.
	      CTRL-T or CTRL-O to jump back.

` + toDoc(structuredClone(options), {lang: 'en', ns: 'auto-input-switch'}) + footer;
fs.writeFile(dst, out, 'utf8', written(dst));


// --- options doc (ja) ---
dst = root + '/doc/auto-input-switch-options.ja.txt';
out = `
*auto-input-switch-options.ja.txt* - Options for |auto-input-switch.nvim|

==============================================================================
OPTIONS                                         *auto-input-switch-options-ja*

	Note: CTRL-] を押すとカーソル下の |リンク| に飛ぶ。
	      CTRL-T または CTRL-O で戻る。

` + toDoc(structuredClone(options), {lang: 'ja', ns: 'auto-input-switch-ja'}) + footer;
fs.writeFile(dst, out, 'utf8', written(dst));

