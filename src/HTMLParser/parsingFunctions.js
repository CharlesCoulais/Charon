import { AttributeNode } from "./nodes/AttributeNode.js";
import { CharonElement } from "./nodes/Element.js";
import {
  getLastChild,
  lastChildIstextNode,
  createTextNode,
  concatTextNode,
  addWaitingAttributes
} from "./utils.js";


export function createParsingFunctions(hooks) {

  const self = {
    registerTextNode(str, parentEl) {
      let textNode;

      if (lastChildIstextNode(parentEl)) {
        textNode = concatTextNode(str, parentEl);
      } else {
        textNode = createTextNode(str, parentEl);
      }
      hooks.onTextNodeFragment(str, textNode, parentEl);
    },
    createElement(tagName) {
      const el = new CharonElement(tagName);
      // console.log(`%cCreate temporary element: %c<${el.name}>`, 'color: grey', 'color: blue');
      return el;
    },
    registerElement(el, parentEl) {
      if (lastChildIstextNode(parentEl)) {
        hooks.onTextNode(getLastChild(parentEl), parentEl)
      }

      parentEl.children.push(el);
      el.parentNode = parentEl;
      
      hooks.onElement(el, parentEl);
      addWaitingAttributes(el, hooks);
    },
    isSelfClosingEl(el) {
      return el.isSelfClosing ? 1 : 0;
    },
    isOrphanClosingTag(tagName, el) {
      let currentNode = el;
      while (!!currentNode && currentNode.name !== tagName.toUpperCase()){
        currentNode = currentNode.parentNode;
      }
      return !currentNode ? 1 : 0;
    },
    isClosingTagOf(tagName, el) {
      return el.name === tagName.toUpperCase() ? 1 : 0;
    },
    createMissingClosingTag(tagName, el) {
      //console.log(`%cCreate missing closing tag: %c</${el.name}>`, 'color: grey', 'color: blue');
      self.registerClosingTag(tagName, el);
    },
    ignoreOrphanClosingTag(tagName) {
      hooks.onOrphanClosingTag(tagName);
    },
    registerClosingTag(tagName, el) {
      if (lastChildIstextNode(el)) {
        hooks.onTextNode(getLastChild(el), el)
      }
      hooks.onClosingTag(tagName, el);
    },
    registerAttribute(attrName, attrValue, el) {
      const attrNode = new AttributeNode(attrName, attrValue || '');
      el.waitingAttributes ??= [];
      el.waitingAttributes.push(attrNode);
    },
  };


  return self;
}