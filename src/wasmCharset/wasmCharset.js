import { chronoFetch } from "../timers/chronoFetch.js";
import { chronoWSInstantiateStreaming } from "../timers/chronoWSInstantiateStreaming.js";

// Use my fetch cache to prefetch
chronoFetch('/build/wasmCharset.wasm');

export async function createWasmCharset(str="", options={}) {
  const mem = new WebAssembly.Memory({ initial: 1 });
  const uint8Array = new Int8Array(mem.buffer);
  uint8Array.set(new TextEncoder().encode(str), 0);
  const logKey = typeof options.logKey.trim() === 'string'
    ? options.logKey.trim() + ' '
    : '';

  const importObject = {
    js: {
      mem,
      logChar(charValue) {
        if (options.activeLog !== true) {
          return;
        }
        let char = new TextDecoder().decode(new Uint8Array([charValue]).buffer);

        char = {
          ' ': '/space/',
          '\t': '/\\t/',
          '\n': '/\\n/',
          '\r': '/\\r/'
        }[char] || char;

        console.log(`%c${logKey}CHARSET LOG:`, 'color: green', char);
      },
      logBool(boolValue) {
        if (options.activeLog !== true) {
          return;
        }
        console.log(`%c${logKey}CHARSET LOG:`, 'color: green', !!boolValue);
      },
    },
  };

  const source = await chronoWSInstantiateStreaming(
    chronoFetch('/build/wasmCharset.wasm'),
    importObject,
  );

  return {
    wCharset: {
      mem,
      ...source.instance.exports,
    }
  };
};