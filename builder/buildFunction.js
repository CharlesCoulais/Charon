const { exec } = require('child_process');

function build(filename) {
  console.time('Compiled in');
  const targetFilename = filename.replace(/\.wat$/, '.wasm');
  const sourceFilePath = `./src/${filename}`;
  const buildFilePath = `./build/${targetFilename}`;
  const options = ['--enable-multi-memory'];
  const command = `wat2wasm ${options.join(' ')} ${sourceFilePath} -o ${buildFilePath}`;

  return new Promise(resolve => {
    exec(command, (err, stdout, stderr) => {
      if (stderr) {
        console.error(stderr);
        return;
      }
      stdout && console.log(stdout);
      console.timeEnd('Compiled in');
      resolve();
    });
  });
}

module.exports = {
  build
};