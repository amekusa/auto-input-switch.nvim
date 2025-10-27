import {Marked} from 'marked';
import {
	docWidth, lines,
	h, tag, link, sr,
	codeblock, indentBlock,
} from './helpers.js';

const lf = '\n';

function docRenderer(opts) {
	let {
		docWidth: docw,
		ns,
	} = opts;

	// @see: https://github.com/markedjs/marked/blob/227cad9c9d61da3846112321c0cd7dded25a9316/src/Renderer.ts#L12
	return {
		heading({tokens, depth}) {
			let text = this.parser.parseInline(tokens);
			let slug = text.toLowerCase().replaceAll(/[^\w]+/g, '-');
			return lines(
				'='.repeat(docw),
				h(text, tag(ns + '.' + slug))
			);
		},
		paragraph({tokens}) {
			let text = this.parser.parseInline(tokens);
			return lf + text + lf;
		},
		br() {
			return lf;
		},
		em({tokens}) {
			let text = this.parser.parseInline(tokens);
			return sr(text, '*');
		},
		strong({tokens}) {
			let text = this.parser.parseInline(tokens);
			return sr(text, '**');
		},
		list({items, ordered}) {
			let body = '';
			for (let i = 0; i < items.length; i++) {
			  body += (ordered ? `${i+1}. ` : '- ') + this.listitem(items[i]) + lf;
			}
			return lf + body;
		},
		listitem({tokens, loose}) {
			let text = this.parser.parse(tokens, !!loose);
			return text;
		},
	}
}

export class MD2Doc {
	constructor(opts) {
		this.marked = new Marked();
		this.marked.use({
			renderer: docRenderer(opts),
		});
	}
	parse(md) {
		let r = this.marked.parse(md);
		return r;
	}
}

