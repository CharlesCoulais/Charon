export function createWasmProxy(source, memoryHanler) {

  return new Proxy(source, {
    get(target, key, proxy) {
      if (typeof target.instance.exports[key] === 'function') {
        return (...args) => {
          memoryHanler.set(...args.filter(arg => typeof arg === 'string'));
          return target.instance.exports[key](...args.filter(arg => typeof arg !== 'string'));
        };
      }
      return target[key];
    }
  });
};