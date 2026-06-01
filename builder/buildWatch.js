const fs = require('fs');
const { build } = require('./buildFunction.js');
const { foreachWatFile } = require('./foreachWatFile.js');


// Sequential files compilation
const compilingFiles = new Set();

async function compileFiles() {
  await [...compilingFiles].reduce((previousPromise, filename) => {
    return previousPromise.then(async () => {
      console.log(`Compiling ${filename}...`);
      const succeeded = await build(filename);
      
      if (succeeded) {
        compilingFiles.delete(filename);
      }
    });
  }, Promise.resolve());
}


// Compile files on file change
let compiling = false;

fs.watch(
  './src',
  {
    recursive: true,
  },
  async(eventType, filename) => {
    if (!/\.wat$/.test(filename)) {
      return;
    }

    if (!compiling) {
      compiling = true;
      console.clear();
      console.log(`Change detected in '${filename}'...`);
      compilingFiles.add(filename);

      setTimeout(async () => {
        await compileFiles();
        compiling = false;
      }, 500);
    }
  }
);

// Compile files on start
(async function () {
  console.clear();
  await foreachWatFile(filename => compilingFiles.add(filename));
  await compileFiles();
  console.log('waiting for changes in source wap files...');
})();