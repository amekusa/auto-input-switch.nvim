/**
 * strutil.js
 * @author Satoshi Soma (github.com/amekusa)
 */

const lf = '\n';

export function indent(str, ind = '\t') {
	return ind + str.replaceAll(lf, lf + ind);
}

export function charWidth(char) {
	let cp = char.codePointAt(0);
	return (0x00 <= cp && cp < 0x7f) ? 1 : 2;
}

export function strWidth(str) {
	let r = 0;
	for (let char of str) r += charWidth(char);
	return r;
}

export function wrap(str, width, opts = {}) {
	let {
		indent = '',
		indentWidth = undefined,
		forceBreak = false,
		sep = [
			/[\s,]/,
			'、',
			'。',
		],
	} = opts;
	if (typeof indentWidth != 'number') indentWidth = strWidth(indent);

	let r = [];

	let lineBreak = [lf + indent];
	let lines = str.split(lf);
	for (let i = 0; i < lines.length; i++) {
		let l = lines[i];
		let lw = 0; // line width
		let chars = []; // [ [char, charWidth], ... ]

		for (let char of l) {
			let cw = charWidth(char);
			lw += cw;
			if (lw > width) { // needs to wrap
				lw = 0;

				let found = false;
				find_sep:
				for (let j = chars.length - 1; j > 0; j--) {
					let c = chars[j];
					if (c === lineBreak) break;

					for (let ii = 0; ii < sep.length; ii++) {
						let s = sep[ii];
						if (s instanceof RegExp) {
							if (c[0].match(s)) {
								found = j;
								break find_sep;
							}
						} else if (c[0] == s) {
							found = j;
							break find_sep;
						}
					}
					lw += c[1];
				}
				if (found) { // separator found
					chars.splice(found+1, 0, lineBreak);
					lw += indentWidth;
				} else if (forceBreak || cw > 1) { // separator not found; force break
					chars.push(lineBreak);
					lw = cw + indentWidth;
				}
			}
			chars.push([char, cw]);
		}
		r.push(chars.map(each => each[0]).join(''));
	}
	return r.join(lf);
}

export function padStart(str, width, pad = ' ') {
	let short = width - strWidth(str);
	return short <= 0 ? str : (pad.repeat(Math.floor(short / strWidth(pad))) + str);
}

export function padEnd(str, width, pad = ' ') {
	let short = width - strWidth(str);
	return short <= 0 ? str : (str + pad.repeat(Math.floor(short / strWidth(pad))));
}

export function padMiddle(start, end, width, margin = 0, pad = ' ') {
	let sw = strWidth(start);
	let ew = strWidth(end);
	let short = width - (sw + ew);
	if (short <= margin) {
		short = width - ew;
		start += lf;
	}
	return short < 0
		? (start + end)
		: (start + pad.repeat(Math.floor(short / strWidth(pad))) + end);
}

export function sr(str, start, end = null) {
	return start + str + (end || start);
}

export function lines(first, ...rest) {
	if (!first) first = '';
	for (let i = 0; i < rest.length; i++) {
		let next = rest[i];
		if (!next) continue;
		first += (first.endsWith(lf) || next.startsWith(lf)) ? next : (lf + next);
	}
	return first;
}

