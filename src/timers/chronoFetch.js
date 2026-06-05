const cache = {};
const counter = {};

export async function chronoFetch(path, ...args) {
  counter[path] ??= 0;
  const count = ++counter[path];

  console.time(`${path} (${count}) fetched in:`);
  cache[path] ??= fetch(path, ...args);
  const response = await cache[path];
  console.timeEnd(`${path} (${count}) fetched in:`);

  return response.clone();
}