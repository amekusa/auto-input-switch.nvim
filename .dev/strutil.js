/**
 * strutil.js
 * @author Satoshi Soma (github.com/amekusa)
 */

const lf = '\n';

export function strWidth(str) {
	let r = 0;
	for (let char of str) {
		let cp = char.codePointAt(0);
		r += (0x00 <= cp && cp < 0x7f) ? 1 : 2
	}
	return r;
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
	for (let i = 0; i < rest.length; i++) {
		let next = rest[i];
		first += (first.endsWith(lf) || next.startsWith(lf)) ? next : (lf + next);
	}
	return first;
}

