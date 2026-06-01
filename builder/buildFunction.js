const { exec } = require('child_process');
const { mkdirSync } = require('fs');
const { dirname } = require('path');


let building = false;

function build(filename) {
  !building && console.time('Compiled in');
  building = true;

  const targetFilename = filename.replace(/\.wat$/, '.wasm');
  const sourceFilePath = `./src/${filename}`;
  const buildFilePath = `./build/${targetFilename}`;
  const options = ['--enable-multi-memory'];
  const command = `wat2wasm ${options.join(' ')} ${sourceFilePath} -o ${buildFilePath}`;
  mkdirSync(dirname(buildFilePath), { recursive: true });
  
  return new Promise(resolve => {
    exec(command, (err, stdout, stderr) => {
      if (stderr) {
        console.error(stderr);
        resolve(false);
      } else {
        stdout && console.log(stdout);
        building && console.timeEnd('Compiled in');
        building = false;
        resolve(true);
      }
    });
  });
}

module.exports = { build };