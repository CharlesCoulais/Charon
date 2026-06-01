export class CharonElement {
  children = [];
  attributes = [];

  constructor(nodeName) {
    this.name = nodeName.toUpperCase();
  }
}