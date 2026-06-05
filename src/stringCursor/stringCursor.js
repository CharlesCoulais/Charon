import { chronoFetch } from "../timers/chronoFetch.js";


// Use my fetch cache to prefetch
chronoFetch('/build/stringCursor.wasm');

export async function createStringCursor(str="", size = 1) {
  const mem = new WebAssembly.Memory({ initial: size });
  const uint8Array = new Int8Array(mem.buffer);
  uint8Array.set(new TextEncoder().encode(str), 1);

  const importObject = { js: {
    mem,
    slice(start, end) {
      if (end < start) {
        return '';
      }

      const slice = uint8Array.slice(start, end);
      const str = new TextDecoder().decode(slice);

      return str;
    },
    logCursor(index, charValue) {
      const char = new TextDecoder().decode(new Uint8Array([charValue]).buffer);
      console.log('%cWSTRING LOG:', 'color: green', index, `"${char}"`);
    }
  }};

  const source = await WebAssembly.instantiateStreaming(
    chronoFetch('/build/stringCursor.wasm'),
    importObject,
  );

  return {
    cursor: {
      ...source.instance.exports,
    },
    setContent(str) {
      uint8Array.set(new TextEncoder().encode(str), 1);
      uint8Array.set([0], str.length + 1);
      source.instance.exports.init();
    },
  };
};