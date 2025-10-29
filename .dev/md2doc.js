import {Marked} from 'marked';
import ContextStack from './cstack.js';
import {
	docWidth, lines,
	h, tag, link, sr,
	codeblock, indentBlock,
} from './helpers.js';

const lf = '\n';
const lflf = lf.repeat(2);

function docRenderer(opts) {
	const {
		ns, // namespace
		docw = 78, // doc width
		shiftHL = 0, // shift heading level
		indent = '  ',
	} = opts;

	const cs = new ContextStack();

	// @see: https://github.com/markedjs/marked/blob/227cad9c9d61da3846112321c0cd7dded25a9316/src/Renderer.ts#L12
	return {
		heading({tokens, depth}) {
			depth += shiftHL;
			if (depth < 1) return '';
			let text = this.parser.parseInline(tokens);
			if (depth < 3) {
				text = (depth == 1 ? '=' : '-').repeat(docw) + lf + h(text, tag(ns + '.' + text.toLowerCase().replaceAll(/[^\w]+/g, '-')));
			} else {
				text = (depth == 3 ? text.toUpperCase() : text) + ' ~';
			}
			return sr(text, lf);
		},
		paragraph({tokens}) {
			let text = this.parser.parseInline(tokens);
			return cs.get('list') ? text : sr(text, lf);
		},
		br() {
			let c = cs.get('list');
			return c ? (lf + indent.repeat(c.depth + 1)) : lf;
		},
		em({tokens}) {
			let text = this.parser.parseInline(tokens);
			return text;
		},
		strong({tokens}) {
			let text = this.parser.parseInline(tokens);
			return sr(text, '*');
		},
		list({items, ordered}) {
			let c = cs.get('list', {depth: 0}, next => {next.depth++});
			let ind = c.depth ? indent.repeat(c.depth) : '';
			let body = '';
			for (let i = 0; i < items.length; i++) {
				let item = this.listitem(items[i]).trim();
				body += ind + (ordered ? `${i+1}. ` : '- ') + item + lf;
			}
			cs.pop();
			return lf + body;
		},
		listitem({tokens, loose}) {
			let text = this.parser.parse(tokens, !!loose);
			return text;
		},
		codespan({text}) {
			return sr(text, '`');
		},
		code({text, lang, escaped}) {
			return codeblock(text, lang, indent);
		}
	}
}

export class MD2Doc {
	constructor(opts) {
		this.opts = opts;
		this.marked = new Marked();
		this.marked.use({
			renderer: docRenderer(opts),
		});
	}
	parse(md) {
		let {
			header,
			footer,
		} = this.opts;
		let body = this.marked.parse(md);
		return lines(
			header,
			body,
			footer
		).trim();
	}
}

