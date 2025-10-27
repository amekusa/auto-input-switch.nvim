import {sr, padMiddle} from './strutil.js';

export {sr, lines} from './strutil.js';

let docw = 78; // document width
export function docWidth(set = 0) {
	if (set > 0) docw = set;
	return docw;
}

export function indentBlock(str, ind = '\t') {
	return ind + str
		.replaceAll('\n', '\n' + ind)
		.replaceAll(ind + '<', '<');
}

export function h(left, right) {
	return padMiddle(left, right, docw, 4);
}

export function tag(str) {
	return sr(str, '*');
}

export function link(str) {
	return sr(str, '|');
}

export function codeblock(str, lang = '', ind = '\t') {
	return `>${lang}\n${indentBlock(str, ind)}\n<\n`;
}

