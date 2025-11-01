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
			' ',
			'、',
			'。',
		],
	} = opts;
	if (typeof indentWidth != 'number') indentWidth = indent ? strWidth(indent) : 0;

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
				let ww = 0; // wrap width
				let wp = 0; // wrap position

				find_sep:
				for (let j = chars.length - 1; j > 0; j--) {
					let c = chars[j];
					if (c === lineBreak) break;
					ww += c[1];

					for (let ii = 0; ii < sep.length; ii++) {
						let s = sep[ii];
						if (s instanceof RegExp) {
							if (c[0].match(s)) {
								wp = j;
								break find_sep;
							}
						} else if (c[0] === s) {
							wp = j;
							break find_sep;
						}
					}
				}
				if (wp) { // separator found
					chars.splice(wp + 1, 0, lineBreak); // insert linebreak
					lw = indentWidth + ww; // new line width

				} else if (forceBreak || cw > 1) { // separator not found; force break
					chars.push(lineBreak); // linebreak here
					lw = indentWidth + cw; // new line width
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

