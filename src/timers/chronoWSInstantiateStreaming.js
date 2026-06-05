export async function chronoWSInstantiateStreaming(...args) {
  //console.time(`Instanciate in:`);
  const response = await WebAssembly.instantiateStreaming(...args);
  //console.timeEnd(`Instanciate in:`);
  return response;
}