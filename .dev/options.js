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
 * @param {string} opts.header - Header text
 * @param {string} opts.ns - Namespace
 * @param {string} opts.lang - Language
 * @param {string[]} stack - Object key stack
 * @return {string} a Vim help doc
 */
function toDoc(data, opts, stack = null) {
	if (!data || typeof data != 'object') return '';

	let {
		header = '',
		ns = '',
		lang = 'en',
	} = opts;

	let r = '';

	if ('__default' in data) {
		r = toLua(data.__default, {lang});
		if (r.match('\n')) r = `Default: >lua\n` + r + `\n<\n`;
		else r = 'Default: `' + r + '`\n';
		delete data.__default;
	}
	if ('__desc' in data) {
		if (data.__desc[lang]) r += data.__desc[lang] + '\n';
		delete data.__desc;
	}

	if (r && stack) { // section header
		r = '\t' + r.replaceAll('\n', '\n\t');
		r = r.replaceAll('\t<\n', '<\n');

		let head = stack.join('.');
		let tag = `*${ns}.${head}*`;
		let pad = 78 - (head.length + tag.length);
		head += pad < 4 ? ('\n' + tag.padStart(78, ' ')) : (' '.repeat(pad) + tag);
		r = head + '\n' + r + '\n\n';
	}

	let keys = Object.keys(data);
	for (let i = 0; i < keys.length; i++) {
		let k = keys[i];
		let v = data[k];
		r += toDoc(v, opts, stack ? [...stack, k] : [k]);
	}

	if (!stack) {
		r = header.trim() + '\n\n' + r + '\nvim:tw=78:ts=4:noet:ft=help:norl:';
	}
	return r;
}

let options = yaml.parse(fs.readFileSync(base + '/options.yml', 'utf8'));
let out, dst, header;
let written = file => {
	return err => {
		if (err) throw err;
		console.log('Written:', file);
	}
};

// defaults.lua
out = 'return ' + toLua(structuredClone(options), {lang: 'en'});
dst = root + '/lua/auto-input-switch/defaults.lua';
fs.writeFile(dst, out, 'utf8', written(dst));

// defaults.ja.lua
out = 'return ' + toLua(structuredClone(options), {lang: 'ja'});
dst = root + '/lua/auto-input-switch/defaults.ja.lua';
fs.writeFile(dst, out, 'utf8', written(dst));

// help docs
//// english
header = `
*auto-input-switch-options.txt*    For auto-input-switch.nvim

==============================================================================
OPTIONS                                            *auto-input-switch-options*
`;
out = toDoc(structuredClone(options), {header, lang: 'en', ns: 'auto-input-switch'});
dst = root + '/doc/auto-input-switch-options.txt';
fs.writeFile(dst, out, 'utf8', written(dst));

//// japanese
header = `
*auto-input-switch-options.ja.txt*    For auto-input-switch.nvim

==============================================================================
OPTIONS                                         *auto-input-switch-options-ja*
`;
out = toDoc(structuredClone(options), {header, lang: 'ja', ns: 'auto-input-switch-ja'});
dst = root + '/doc/auto-input-switch-options.ja.txt';
fs.writeFile(dst, out, 'utf8', written(dst));

