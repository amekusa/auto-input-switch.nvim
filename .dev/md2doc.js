import {Marked} from 'marked';
import ContextStack from './cstack.js';
import {
	docWidth, lines,
	h, tag, link, sr,
	codeblock, indent,
} from './helpers.js';

const lf = '\n';

function docRenderer(opts) {
	const {
		ns, // namespace
		docw = 78, // doc width
		shiftHL = 0, // shift heading level
		indentStr = '  ',
		baseURL = '', // for relative URLs
		images = true,
	} = opts;

	const cs = new ContextStack();

	// @see: https://github.com/markedjs/marked/blob/227cad9c9d61da3846112321c0cd7dded25a9316/src/Renderer.ts#L12
	return {
		heading({tokens, depth}) {
			depth += shiftHL;
			if (depth < 1) return '';
			let text = this.parser.parseInline(tokens);
			if (depth < 3) {
				text = h(text, tag(ns + '.' + text.toLowerCase().replaceAll(/[^\w]+/g, '-')));
				text = (depth == 1 ? '=' : '-').repeat(docw) + lf + text;
			} else {
				text = (depth == 3 ? text.toUpperCase() : text) + ' ~';
			}
			return sr(text, lf);
		},
		paragraph({tokens}) {
			let text = this.parser.parseInline(tokens).trim();
			return cs.get('list') ? text : block(text);
		},
		br() {
			let c = cs.get('list');
			return c ? (lf + indentStr.repeat(c.depth + 1)) : lf;
		},
		em({tokens}) {
			let text = this.parser.parseInline(tokens);
			return text;
		},
		strong({tokens}) {
			let text = this.parser.parseInline(tokens);
			return text;
		},
		list({items, ordered}) {
			let c = cs.get('list', {depth: 0}, next => {next.depth++});
			let ind = c.depth ? indentStr.repeat(c.depth) : '';
			let body = lf;
			for (let i = 0; i < items.length; i++) {
				body += ind + (ordered ? `${i+1}. ` : '- ') + this.listitem(items[i]) + lf;
			}
			cs.pop();
			return body;
		},
		listitem({tokens, loose}) {
			let text = this.parser.parse(tokens, !!loose).trim();
			return text;
		},
		link({href, tokens}) {
			let text = this.parser.parseInline(tokens);
			return `${text} (${url(href, baseURL)})`;
		},
		image({href, title, text}) {
			if (!images) return '';
			href = url(href, baseURL);
			return text ? `[img: ${text} (${href})]` : `[img: ${href}]`;
		},
		blockquote({tokens}) {
			let body = this.parser.parse(tokens).trim();
			body = body.replace(/^\[!([A-Z]+)\]\n/, '$1:\n');
			return sr(indent(body, '▎ '), lf);
		},
		codespan({text}) {
			return sr(text, '`');
		},
		code({text, lang, escaped}) {
			return codeblock(text, lang, indentStr);
		},
		html({text, block:isBlock}) {
			text = text.replaceAll(/<\/?(:?details|summary)>/g, '');
			return isBlock ? block(text) : text;
		}
	}
}

function block(str) {
	str = str.trim();
	return str ? sr(str, lf) : '';
}

function url(str, base = '') {
	let m = str.match(/^[a-z]+:\/\//);
	if (m || !base) return str;
	return base.replace(/\/$/, '') + '/' + str.replace(/^\//, '');
}

export class MD2Doc {
	constructor(opts) {
		this.opts = opts;
		this.marked = new Marked();
		this.marked.use({
			renderer: docRenderer(opts),
		});
	}
	preprocess(md) {
		md = md.replaceAll(/<!--+\s*TRUNCATE:START\s*--+>.*?<!--+\s*TRUNCATE:END\s*--+>/gs, '');
		return md;
	}
	parse(md) {
		let {
			header,
			footer,
		} = this.opts;
		md = this.preprocess(md);
		md = this.marked.parse(md);
		return lines(
			header,
			md,
			footer
		).trim();
	}
}

