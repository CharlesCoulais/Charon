import { chronoFetch } from "../timers/chronoFetch.js";
import { chronoWSInstantiateStreaming } from "../timers/chronoWSInstantiateStreaming.js";

// Singleton
let promise = null;

// Use my fetch cache to prefetch
chronoFetch('/build/wasmLogicOperators.wasm');

export async function createWasmLogicOperators() {
  promise ??= chronoWSInstantiateStreaming(
    chronoFetch('/build/wasmLogicOperators.wasm'),
  );

  return {
    logicOperators: {
      ...(await promise).instance.exports,
    }
  };
};