import { getLastChild, lastChildIstextNode } from "./utils.js";


export function createHooks(options={}) {
  let clientTextFragments = new Map();
  let clientElements = new Map();

  return {
    start(rootEl) {
      const clientValue = options.start?.();
      clientElements.set(rootEl, clientValue);
    },
    complete(rootEl) {
      if (lastChildIstextNode(rootEl)) {
        this.onTextNode(getLastChild(rootEl), rootEl);
      }
      const clientValue = clientElements.get(rootEl);

      clientTextFragments = new Map();
      clientElements = new Map();

      return options.complete?.(clientValue);
    },
    onTextNodeFragment(str, textNode, parentEl) {
      const clientParentElValue = clientElements.get(parentEl);
      const clientPreviousTextFagmentValue = clientTextFragments.get(textNode);
      const clientTextFragValue = options.onTextNodeFragment?.(str, clientPreviousTextFagmentValue, clientParentElValue);
      clientTextFragments.set(textNode, clientTextFragValue);
    },
    onTextNode(textNode, parentEl) {
      const clientParentElValue = clientElements.get(parentEl);
      options.onTextNode?.(textNode.textContent, clientParentElValue);
    },
    onElement(el, parentEl) {
      const clientParentElValue = clientElements.get(parentEl);
      const clientElValue = options.onElement?.(el.name, clientParentElValue, el.isSelfClosing);
      clientElements.set(el, clientElValue);
    },
    onClosingTag(tagName, el) {
      const clientElValue = clientElements.get(el);
      options.onClosingTag?.(tagName, clientElValue);
    },
    onOrphanClosingTag(tagName) {
      console.log(`%cOrphan closing tag - %cIGNORED%c: %c</${tagName.toUpperCase()}>`, 'color: grey', 'color: red', '', 'color: blue')
    },
    onAttributeNode(attrNode, el) {
      const clientElValue = clientElements.get(el);
      options.onAttributeNode?.(attrNode.name, attrNode.value, clientElValue);
    },
    onAttributeNodeDoublon(attrNode, el) {
      const clientElValue = clientElements.get(el);
      options.onAttributeNodeDoublon?.(attrNode.name, attrNode.value, clientElValue);
    },
    onAttributes(attributes, el) {
      const clientElValue = clientElements.get(el);
      options.onAttributes?.(attributes, clientElValue);
    },
  }
}