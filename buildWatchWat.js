const { exec } = require('child_process');
const fs = require('fs');


fs.watch('./src', {
    recursive: true,
    ignore: filename => {
      console.log(filename);
      return !/\.wat$/.test(filename);
    },
  },
  async(eventType, filename) => {
    if (!/\.wat$/.test(filename)) {
      return;
    }
    console.log(eventType, 'Change detected in "' +  filename + '"...');
    const targetFilename = filename.replace(/\.wat$/, '.wasm');
    const command = `wat2wasm ./src/${filename} -o ./build/${targetFilename}`;
    await exec(command, (err, stdout, stderr) => {
      stdout && console.log(stdout);
      stderr && console.error(stderr);
    });
  }
);
console.clear();
console.log('waiting for changes in source wap files...')