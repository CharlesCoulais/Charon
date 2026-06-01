import { RootElement } from "../nodes/rootElement.js";
import { parsingChars } from "../parser/chars.js";
import { exportedFunctions } from "../parser/parsingFunctions.js";
import { WasmMamoryHandler } from "../wasm/WasmMemoryHandler.js";
import { createWasmLogger } from "../wasmLogger/logger.js";


const parserReady = new Promise(async resolve => {
  const mem = new WebAssembly.Memory({ initial: 1 });
  const memoryHanler = new WasmMamoryHandler(mem);
  const wasmLoggerExports = await createWasmLogger();

  const importObject = {
    shared: { mem },
    export: Object.entries(exportedFunctions).reduce((cum, [key, fn]) => {
      cum[key] = fn.bind(memoryHanler);
      return cum;
    }, {}),
    ...wasmLoggerExports,
  };

  const source = await WebAssembly.instantiateStreaming(
    fetch('/build/HTMLParser.wasm'),
    importObject,
  );

  resolve((htmlStr, options) => {
    memoryHanler.set(...parsingChars, htmlStr);
    return source.instance.exports.parseHTML(new RootElement());
  });
});


export const parser = {
  parseHTML(htmlStr, options) {
    return parserReady.then(parseFn => parseFn(htmlStr, options));
  }
};