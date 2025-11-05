/**
 * Context stack
 * @author Satoshi Soma (github.com/amekusa)
 */
class ContextStack {
	constructor() {
		this.stack = [];
	}

	push(atts, c, next = null) {
		let {id, classes} = parseAtts(atts);
		if (next) {
			atts = {classes};
			let anc = this.get(atts); // ancestor
			if (anc) {
				anc = structuredClone(anc);
				return this.push(atts, next(anc) || anc);
			}
		}
		if (id) c._id = id;
		if (classes) c._classes = classes;
		this.stack.push(c);
		return c
	}

	pop() {
		return this.stack.pop();
	}

	get(atts, fb = null) {
		let {id, classes} = parseAtts(atts);
		let found;
		find_c:
		for (let i = this.stack.length - 1; i >= 0; i--) {
			let c = this.stack[i];
			if (id && id != c._id) continue;
			if (classes) {
				if (!c._classes) continue;
				for (let i = 0; i < classes.length; i++) {
					if (!c._classes.includes(classes[i])) continue find_c;
				}
			}
			found = c;
			break;
		}
		return found || fb;
	}
}

function parseAtts(atts) {
	if (typeof atts == 'object') return atts;
	let r = {};
	atts = atts.split('.');
	if (!atts[0]) atts.shift();
	else if (atts[0].startsWith('#')) r.id = atts.shift().substring(1);
	if (atts.length > 0) {
		r.classes = [];
		for (let i = 0; i < atts.length; i++) r.classes.push(atts[i]);
	}
	return r;
}

export default ContextStack;
