const { build } = require('./buildFunction.js');
const { foreachWatFile } = require('./foreachWatFile.js');


foreachWatFile(filename => {
  console.log(`Compiling ${filename}...`);
  build(filename);
});