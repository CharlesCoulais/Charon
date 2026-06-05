import { CharonTextNode } from "./nodes/TextNode.js";


export function getLastChild(el) {
  return el.children[el.children.length - 1];
}

export function lastChildIstextNode(el) {
  return getLastChild(el) instanceof CharonTextNode;
}

export function createTextNode(str, parentEl) {
  const node = new CharonTextNode(str);
  parentEl.children.push(node);
  node.parentNode = parentEl;
  return node;
}

export function concatTextNode(str, parentEl) {
  const node = getLastChild(parentEl);
  node.textContent += str;
  return node;
}

export function addWaitingAttributes(el, hooks) {
  if (!el.waitingAttributes) {
    return;
  }

  const attributes = {};

  el.waitingAttributes.forEach(attrNode => {
    const hasAttribute = el.attributes.some(addedAttrNode => addedAttrNode.name === attrNode.name);

    if (!hasAttribute) {
      el.attributes.push(attrNode);
      attributes[attrNode.name] = attrNode.value;
      hooks.onAttributeNode(attrNode, el);
    } else {
      hooks.onAttributeNodeDoublon(attrNode, el);
    }
  });
  delete el.waitingAttributes;
  hooks.onAttributes(attributes);
}