import { chronoFetch } from "../timers/chronoFetch.js";
import { chronoWSInstantiateStreaming } from "../timers/chronoWSInstantiateStreaming.js";


let tokenList = [];

const importObject = {
  export: {
    logRef(value) {
      console.log('%cWASM LOG REF:', 'color: green', value);
    },
    log(typeId, rawValue) {
      let value = rawValue;
      
      switch(typeId) {
        case 1:
          value = !!rawValue;
          break;
        case 3:
          value = new TextDecoder().decode(new Uint16Array([rawValue]).buffer);
          break;
        case 4:
          value = tokenList[rawValue];
          console.log('%cWASM LOG START:', 'color: green', value);
          return;
        case 5:
          value = tokenList[rawValue];  
          console.log('%cWASM LOG END:', 'color: green', value);
          return;
        default:
          break;
      }
      
      console.log('%cWASM LOG:', 'color: green', value);
    },
  }
};


export async function createWasmLogger(tokens = []) {
  tokenList = tokens;
  const source = await chronoWSInstantiateStreaming(
    chronoFetch('/build/logger.wasm'),
    importObject,
  );

  return { logger: source.instance.exports };
};