/**
 * Context stack
 * @author Satoshi Soma (github.com/amekusa)
 */
class ContextStack {
	constructor() {
		this.stack = [];
	}

	push(type, c) {
		c.__type = type;
		this.stack.push(c);
		return c
	}

	pop() {
		return this.stack.pop();
	}

	get(type, first = null, next = null) {
		for (let i = this.stack.length - 1; i >= 0; i--) {
			if (this.stack[i].__type === type) {
				if (next) {
					let c = structuredClone(this.stack[i]);
					return this.push(type, next(c) || c);
				}
				return this.stack[i];
			}
		}
		return first ? this.push(type, first) : null;
	}
}

export default ContextStack;
