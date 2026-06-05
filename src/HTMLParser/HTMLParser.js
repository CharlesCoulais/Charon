import { RootElement } from "./nodes/rootElement.js";
import { spaceCharsetString, tagnameCharsetString, quoteCharsetString } from "./charsets.js";
import { createParsingFunctions } from "./parsingFunctions.js";
//import { createWasmLogger } from "../wasmLogger/logger.js";
import { createWasmLogicOperators } from "../wasmLogicOperators/wasmLogicOperators.js";
import { createStringCursor } from "../stringCursor/stringCursor.js";
import { createWasmCharset } from "../wasmCharset/wasmCharset.js";
import { createHooks } from "./hooks.js";
import { chronoFetch } from "../timers/chronoFetch.js";
import { chronoWSInstantiateStreaming } from "../timers/chronoWSInstantiateStreaming.js";


// Use my fetch cache to prefetch
chronoFetch('/build/HTMLParser.wasm');

export async function createHTMLParser(options) {
  console.groupCollapsed('Init');
  console.time('Init done in');

  // parallele loadings
  const [
    { cursor: htmlCursor, setContent },
    { wCharset: spaceCharset },
    { wCharset: tagnameCharset },
    { wCharset: quoteCharset },
    { logicOperators },
    //{ logger },
    fetched
  ] = await Promise.all([
    createStringCursor(),
    createWasmCharset(spaceCharsetString, { activeLog: false, logKey: 'Spaces' }),
    createWasmCharset(tagnameCharsetString, { activeLog: true, logKey: 'Tagname' }),
    createWasmCharset(quoteCharsetString, { activeLog: true, logKey: 'Tagname' }),
    createWasmLogicOperators(),
    //createWasmLogger(),
    chronoFetch('/build/HTMLParser.wasm')
  ]);

  const hooks = createHooks(options);
  const importObject = {
    js: createParsingFunctions(hooks),
    htmlCursor,
    spaceCharset,
    tagnameCharset,
    quoteCharset,
    logicOperators,
    //logger,
  };

  const source = await chronoWSInstantiateStreaming(
    fetched,
    importObject,
  );

  console.groupEnd();
  console.timeEnd('Init done in');

  return {
    parse(htmlStr) {
      console.time('HTML parsed in');
      setContent(htmlStr);
      const rootEl = new RootElement();
      hooks.start(rootEl);
      const parsed = source.instance.exports.parseHTML(rootEl);
      const result = hooks.complete(parsed) || parsed;
      console.timeEnd('HTML parsed in');
      return result;
    }
  };
};