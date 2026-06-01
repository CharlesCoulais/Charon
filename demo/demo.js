import Charon from '../src/Charon.js';

window.addEventListener('DOMContentLoaded', e => {
  document.querySelector('#parseBt').addEventListener('click', parse);
  parse();
});

async function parse() {
  //console.clear();
  console.log('START TO PARSE...');
  const html = document.querySelector('textarea').value;
  const rootEl = await Charon.parser.parseHTML(html);
  console.log('COMPLETE!', rootEl);
}