export const logHooks = {
    /*onTextNodeFragment(str, previous='', parentNode) {
      const concat = previous + str;

      if (previous) {
        console.log(`%cConcat to previous text node: "%c${concat}%c"`, 'color: grey', '', 'color: grey');
      }
      else {
        console.log(`%cCreate Text node: "%c${str}%c"`, 'color: grey', '', 'color: grey');
      }

      return concat;
    },*/
    onTextNode(str, parentNode) {
      console.log(`%cText node: %c"${str}"`, 'color: grey', '');
    },
    onElement(nodeName, parentNode, isSelfClosing) {
      if (isSelfClosing) {
        console.groupCollapsed(`%c<${nodeName}/>`, 'color: blue');
        console.groupEnd();
      } else {
        console.group(`%c<${nodeName}>`, 'color: blue');
      }
    },
    onClosingTag(tagName, element) {
      console.log(`%c</${tagName.toUpperCase()}>`, 'color: blue');
      console.groupEnd();
    },
    onOrphanClosingTag(tagName) {
      console.log(`%cOrphan closing tag - %cIGNORED%c: %c</${tagName.toUpperCase()}>`, 'color: grey', 'color: red', '', 'color: blue');
    },
    /*onAttributeNode(attrName, attrValue, el) {
      console.log(`%cAttribute: %c${attrName}%c="%c${attrValue}%c"`, 'color: grey', 'color: purple', '', 'color: pink', '');
    },*/
    onAttributeNodeDoublon(attrName, attrValue, el) {
      console.log(`%cAttribute doublon - %cIGNORED%c: %c${attrName}%c="%c${attrValue}%c"`, 'color: grey', 'color: red', '', 'color: purple', '', 'color: pink', '');
    },
    onAttributes(attributes, el) {
      console.log(`%cAttributes:`, 'color: purple', attributes);
    },
    start() {
      console.log('START TO PARSE...');
      //return 42;
    },
    complete(startValue) {
      console.log('...COMPLETE!');
      //return startValue;
    },
  };