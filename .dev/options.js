#!/usr/bin/env node

import fs from 'node:fs';
import yaml from 'yaml';

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

let parsed = toLua(yaml.parse(fs.readFileSync('./options.yml', 'utf8')), {lang: 'en'});
console.debug(parsed);
