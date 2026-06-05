import { selfClosingTags } from "../selfClosingTagList.js";


export class CharonElement {
  children = [];
  attributes = [];
  isSelfClosing = false;

  constructor(nodeName) {
    this.name = nodeName.toUpperCase();
    this.isSelfClosing = selfClosingTags.includes(this.name);
  }
}