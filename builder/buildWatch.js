const fs = require('fs');
const { build } = require('./buildFunction.js');
const { foreachWatFile } = require('./foreachWatFile.js');


const compiling = {};

fs.watch(
  './src',
  {
    recursive: true,
  },
  async(eventType, filename) => {
    if (!/\.wat$/.test(filename)) {
      return;
    }

    if (!compiling[filename]) {
      console.clear();
      console.log(`Change detected in '${filename}'...`);
      compiling[filename] = setTimeout(async() => {
        await build(filename);
        delete compiling[filename];
      }, 500);
    }
  }
);

(async function () {
  console.clear();
  await foreachWatFile(filename => {
    console.log(`Compiling ${filename}...`);
    return build(filename);
  });
  console.log('waiting for changes in source wap files...');
})();