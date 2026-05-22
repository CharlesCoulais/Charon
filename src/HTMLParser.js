import { AttributeNode } from "./nodes/AttributeNode.js";
import { CharonElement } from "./nodes/Element.js";
import { CharonTextNode } from "./nodes/TextNode.js";
import { createWasmInstance } from "./wasm/WasmInstance.js";


const selfClosingTags = [
  'AREA',
  'BASE',
  'BR',
  'COL',
  'EMBED',
  'HR',
  'IMG',
  'INPUT',
  'LINK',
  'META',
  'PARAM',
  'SOURCE',
  'TRACK',
  'WBR',
  'COMMAND',
  'KEYGEN',
  'MENUITEM',
  'FRAME',
];


const parsingChars = [
  '<',
  '>',
  '/',
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-0123456789',
  ' \n\r\t',
  '=',
  '"\'',
];


const importObject = {
  export: {
    log(...args) {
      const [typeId, rawValue] = args;
      let value = rawValue;
      
      if (typeId === 1) {
        value = !!rawValue;
      } else if (typeId === 3) {
        value = new TextDecoder().decode(new Uint16Array([rawValue]).buffer);
      }
      
      console.log('%cWASM LOG:', 'color: green', value);
    },
    registerTextNode(startIndex, endIndex, el) {
      const str = this.getString(startIndex, endIndex);

      if (el.children[el.children.length - 1] instanceof CharonTextNode) {
        const node = el.children[el.children.length - 1];
        node.textContent += str;
        console.log(`%cConcat to previous text node: "%c${node.textContent}%c"`, 'color: grey', '', 'color: grey');
      } else {
        const node = new CharonTextNode(str);
        el.children.push(node);
        node.parentNode = el;
        console.log(`%cText node: "%c${node.textContent}%c"`, 'color: grey', '', 'color: grey');
      }
    },
    isSelfClosingEl(el) {
      return selfClosingTags.includes(el.name) ? 1 : 0;
    },
    createElement(startIndex, endIndex) {
      const tagName = this.getString(startIndex, endIndex);
      const el = new CharonElement(tagName);
      console.log(`%cCreate temporary element: %c<${el.name}>`, 'color: grey', 'color: blue');
      return el;
    },
    registerElement(el, parentEl) {
      const isSelfClosing = selfClosingTags.includes(el.name);
      const logAction = isSelfClosing ? 'groupCollapsed' : 'group';
      
      console[logAction](`%cRegister element: %c<${el.name}>`, 'color: grey', 'color: blue');

      parentEl.children.push(el);
      el.parentNode = parentEl;
    },
    registerElementAttribute(nameStart, nameEnd, valueStart, valueEnd, el) {
      const attrName = this.getString(nameStart, nameEnd);
      const attrValue = this.getString(valueStart, valueEnd);
      const hasAttribute = el.attributes.some(attrNode => attrNode.name === attrName);

      if (!hasAttribute) {
        const attr = new AttributeNode(attrName, attrValue);
        console.log(`%cAttribute: %c${attr.name}%c="%c${attr.value}%c"`, 'color: grey', 'color: purple', '', 'color: pink', '');
        el.attributes.push(attr);
      } else {
        console.log(`%cAttribute doublon - %cIGNORED%c: %c${attrName}%c="%c${attrValue}%c"`, 'color: grey', 'color: red', '', 'color: purple', '', 'color: pink', '');
      }
    },
    logEndTag(startIndex, endIndex, el) {
      const isSelfClosing = selfClosingTags.includes(el.name);
      let tagName = el.name;
      let correspondingEl = el;

      if (!isSelfClosing) {
        tagName = this.getString(startIndex, endIndex);
        
        while (!!correspondingEl && correspondingEl.name !== tagName.toUpperCase()){
          correspondingEl = correspondingEl.parentNode;
        }
      }

      !correspondingEl
        ? console.log(`%cOrphan End tag - %cIGNORED%c: %c</${tagName.toUpperCase()}>`, 'color: grey', 'color: red', '', 'color: blue')
        : console.groupEnd(`%cFound End tag: %c</${tagName.toUpperCase()}>`, 'color: grey', 'color: blue');
    },
    isEndTagOf(startIndex, endIndex, el) {
      const tagName = this.getString(startIndex, endIndex);
      return el.name === tagName.toUpperCase() ? 1 : 0;
    },
    isOrphanEndTag(startIndex, endIndex, el) {
      const tagName = this.getString(startIndex, endIndex);

      let currentNode = el
      while (!!currentNode && currentNode.name !== tagName.toUpperCase()){
        currentNode = currentNode.parentNode;
      }
      //console.log('IS ORPHAN:', tagName, !currentNode);
      return !currentNode ? 1 : 0;
    },
  },
};


let wasmInstance;

export const parser = {
  async parseHTML(htmlStr) {
    if (!wasmInstance) {
      wasmInstance = await createWasmInstance('/build/htmlParser.wasm', importObject);
    }

    return wasmInstance.parseHTML(
      { children: [] },
      ...parsingChars,
      htmlStr,
    )
  }
};