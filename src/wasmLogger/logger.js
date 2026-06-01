const importObject = {
  export: {
    log(typeId, rawValue) {
      let value = rawValue;
      
      switch(typeId) {
        case 1:
          value = !!rawValue;
          break;
        case 3:
          value = new TextDecoder().decode(new Uint16Array([rawValue]).buffer);
        default:
          break;
      }
      
      console.log('%cWASM LOG:', 'color: green', value);
    },
  }
};


export async function createWasmLogger() {
  const source = await WebAssembly.instantiateStreaming(
    fetch('/build/logger.wasm'),
    importObject,
  );

  return { logger: source.instance.exports };
};