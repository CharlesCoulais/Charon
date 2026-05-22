import { WasmMamoryHandler } from "./WasmMemoryHandler.js";
import { createWasmProxy } from "./WasmProxy.js";

export async function createWasmInstance(wasmFileUrl, importObject = {}) {
  const memory = new WebAssembly.Memory({ initial: 1 });
  const memoryHanler = new WasmMamoryHandler(memory);

  importObject = {
    js: { mem: memoryHanler.memory },
    ...createImportProxy(importObject, memoryHanler),
  };
  
  const source = await WebAssembly.instantiateStreaming(
    fetch(wasmFileUrl),
    importObject,
  );

  return createWasmProxy(source, memoryHanler);
}


function createImportProxy(importObj, memoryHanler) {
  return Object.entries(importObj).reduce((cum, [key, value]) => {
    if (typeof value !== 'object' || !Object.keys(value).length) {
      cum[key] = value
    } else {
      cum[key] =  new Proxy(value, {
        get(target, key) {
          if (typeof target[key] === 'function') {
            return (...args) => target[key].apply(memoryHanler, args);
          }
          return value;
        }
      });
    }
    
    return cum;
  }, {});
}