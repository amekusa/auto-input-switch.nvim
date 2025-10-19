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

function toDoc(data, opts, stack = null) {
	if (!data || typeof data != 'object') return '';

	let {
		ns = '',
		lang = 'en',
	} = opts;

	let r = '';

	if ('__desc' in data) {
		r = data.__desc[lang] || '';
		delete data.__desc;
	}
	if ('__default' in data) {
		r = 'Default: ' + toLua(data.__default, {lang}) + '\n' + r;
		delete data.__default;
	}

	if (r && stack) {
		let left = stack.join('.');
		let right = `*${ns}.${left}*`;
		let pad = 78 - (left.length + right.length);
		r = left + ' '.repeat(pad > 0 ? pad : 1) + right + '\n' + r + '\n\n';
	}

	let keys = Object.keys(data);
	for (let i = 0; i < keys.length; i++) {
		let k = keys[i];
		let v = data[k];
		r += toDoc(v, opts, stack ? [...stack, k] : [k]);
	}

	return r;
}

let options = yaml.parse(fs.readFileSync(base + '/options.yml', 'utf8'));

let out, dst;
let written = file => {
	return err => {
		if (err) throw err;
		console.log('Written:', file);
	}
};
out = 'return ' + toLua(structuredClone(options), {lang: 'en'});
dst = root + '/lua/auto-input-switch/defaults.lua';
fs.writeFile(dst, out, 'utf8', written(dst));

out = 'return ' + toLua(structuredClone(options), {lang: 'ja'});
dst = root + '/lua/auto-input-switch/defaults.ja.lua';
fs.writeFile(dst, out, 'utf8', written(dst));

out = toDoc(structuredClone(options), {lang: 'en', ns: 'auto-input-switch'});
dst = root + '/doc/auto-input-switch-options.txt';
fs.writeFile(dst, out, 'utf8', written(dst));

out = toDoc(structuredClone(options), {lang: 'ja'});
dst = root + '/doc/auto-input-switch-options.ja.txt';
fs.writeFile(dst, out, 'utf8', written(dst));

