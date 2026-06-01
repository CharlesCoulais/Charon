const openTagChar = '<';
const closeTagChar = '>';
const endTagMarkerChar = '/';
const tagNameChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-0123456789';
const spacesChars = ' \n\r\t';
const attrDefChar = '=';
const attrStringChars = '"\'';


export const parsingChars = [
  openTagChar,
  closeTagChar,
  endTagMarkerChar,
  tagNameChars,
  spacesChars,
  attrDefChar,
  attrStringChars,
];