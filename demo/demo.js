import Charon from '../src/Charon.js';
import { logHooks } from './hooks.js';


let htmlParser;

window.addEventListener('DOMContentLoaded', async e => {
  htmlParser = await Charon.createHTMLParser(logHooks);

  document.querySelector('#parseBt').addEventListener('click', e => {
    console.clear();
    parse();
  });
  
  parse();
});

async function parse() {
  const html = document.querySelector('textarea').value;
  const rootEl = htmlParser.parse(html);

  console.log('Result:', rootEl);
}