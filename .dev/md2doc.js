import {Marked} from 'marked';
import ContextStack from './cstack.js';
import {
	strWidth, docWidth,
	lines, h, tag, link, sr,
	indent, wrap, codeblock,
} from './helpers.js';

const lf = '\n';

/**
 * MD2Doc
 * @author Satoshi Soma (github.com/amekusa)
 */

function docRenderer(opts) {
	let {
		ns, // namespace
		docw = 78, // doc width
		shiftHL = 0, // shift heading level
		indentStr = '  ',
		indentWidth,
		baseURL = '', // for relative URLs
		images = true,
	} = opts;

	if (!indentWidth) indentWidth = strWidth(indentStr);

	const cs = new ContextStack();

	// @see: https://github.com/markedjs/marked/blob/227cad9c9d61da3846112321c0cd7dded25a9316/src/Renderer.ts#L12
	return {
		heading({tokens, depth}) {
			depth += shiftHL;
			if (depth < 1) return '';
			let text = this.parser.parseInline(tokens).trim();
			if (depth < 3) {
				let slug = /<!--\s*#([a-zA-Z]+)\s*-->/;
				let m = text.match(slug);
				if (m) {
					text = text.replace(slug, '').trim();
					slug = m[1];
				} else slug = text;
				slug = slug.toLowerCase().replaceAll(/[^\w]+/g, '-');
				text = h(text, tag(ns + '.' + slug));
				text = (depth == 1 ? '=' : '-').repeat(docw) + lf + text;
			} else {
				text = (depth == 3 ? text.toUpperCase() : text) + ' ~';
			}
			return sr(text, lf);
		},
		paragraph({tokens}) {
			let text = this.parser.parseInline(tokens).trim();
			text = wrap(text, docw);
			return cs.get('list') ? text : block(text);
		},
		br() {
			return lf;
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
			let c = cs.push('list', {depth: 0}, next => {next.depth++});
			c.ordered = ordered;
			let body = lf;
			for (let i = 0; i < items.length; i++) {
				c.nth = i + 1;
				body += this.listitem(items[i]) + lf;
			}
			cs.pop();
			return body;
		},
		listitem({tokens, loose}) {
			let c = cs.get('list');
			let text = this.parser.parse(tokens, !!loose).trim();
			text = wrap(text, docw - (c.depth + 1) * 2);
			text = (c.ordered ? `${c.nth}. ` : '- ') + indent(text, '  ', true);
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
			body = wrap(body, docw - 2);
			body = body.replace(/^\[!([A-Z]+)\]\n/, '$1:\n'); // gfm special tag
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

