const { join, relative} = require('path');
const fs = require('fs');

const sourcePath = join(__dirname, '../src');

function foreachWatFile(callback, dirPath = sourcePath) {
  return new Promise(resolve => {
    fs.readdir(dirPath, (err, files) => {
      if (err) {
        return console.log('Unable to scan directory: ' + err);
      }

      resolve(
        Promise.all(
          files.map(filename => {
            const path = `${dirPath}/${filename}`
            const isDir = fs.lstatSync(path).isDirectory();

            if (isDir) {
              return foreachWatFile(callback, path);
            }

            if (!/\.wat$/.test(filename)) {
              return;
            }
            
            return callback(relative( './src', path));
          }),
        ),
      );
    });
  });
}


module.exports = { foreachWatFile };