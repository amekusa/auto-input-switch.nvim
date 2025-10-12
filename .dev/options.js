#!/usr/bin/env node

import fs from 'node:fs';
import yaml from 'yaml';

/**
 * Convert a JS object into a Lua expression.
 * @author Satoshi Soma (github.com/amekusa)
 *
 * @param {any} data -
 * @param {object} opts -
 * @param {string} opts.key -
 * @param {number} opts.depth -
 * @param {string} opts.tab -
 * @param {string} opts.comment -
 * @param {string} opts.lang -
 * @return {string} a Lua expression
 */
function toLua(data, opts) {
	let {
		depth = 0,
		tab = '  ',
		key,
		comment = '',
		lang = 'en',
	} = opts;

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
			let _opts = Object.assign({}, opts);
			_opts.comment = data.__desc[lang] || '';
			delete data.__desc;
			return toLua(data, _opts);
		}
		if ('__default' in data) { // special key: __default
			return toLua(data.__default, opts);
		}
		r += '{' + comment + '\n';
		comment = '';
		let _opts = {depth: depth + 1, tab, lang};
		if (Array.isArray(data)) {
			for (let i = 0; i < data.length; i++) {
				r += toLua(data[i], _opts) + '\n';
			}
		} else {
			let keys = Object.keys(data);
			for (let i = 0; i < keys.length; i++) {
				let k = keys[i];
				let v = data[k];
				_opts.key = k;
				r += toLua(v, _opts) + '\n';
			}
		}
		r += ind + '}';
		break;

	case 'string':
		// special tag: <!LITERAL>
		let m = data.match(/^\s*<!LITERAL>(.*)$/); if (m) {
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
