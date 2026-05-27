import { WasmMamoryHandler } from "./WasmMemoryHandler.js";
import { createWasmProxy } from "./WasmProxy.js";

export async function createWasmInstance(wasmFileUrl, importObject = {}) {
  const memoryHanler = new WasmMamoryHandler(importObject.shared.mem);
  
  const source = await WebAssembly.instantiateStreaming(
    fetch(wasmFileUrl),
    createImportProxy(importObject, memoryHanler),
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
          return target[key];
        }
      });
    }
    
    return cum;
  }, {});
}