const { exec } = require('child_process');
const { mkdirSync, existsSync, watch, unlink, rmSync, readdir, lstatSync } = require('fs');
const { dirname, join, basename, relative } = require('path');
const { foreachFile } = require('./foreachFile.js');
const { stdout } = require('process');


// Globals
const config = getBuildConfig();
const sourcePath = join(__dirname, config.src);
const destPath = join(__dirname, config.dest);
const srcExtension = '.wat';
const targetExtension = '.wasm';
const srcExtRegExp = new RegExp(srcExtension.replace('.', '\\.') + '$')

// Get WAT file list
async function getWatFileList() {
  const list = [];
  await foreachSrcFile(filename => list.push(getFileBuildObject(filename)));
  return list;
}

// for each source file
function foreachSrcFile(callback) {
  return foreachFile(callback, sourcePath, srcExtension);
};

// for each files recursive
function foreachFile(callback, dirPath, extensionFilter = null) {
  return new Promise(resolve => {
    readdir(dirPath, (err, files) => {
      if (err) {
        return console.log('Unable to scan directory: ' + err);
      }

      resolve(
        Promise.all(
          files.map(filename => {
            const path = `${dirPath}/${filename}`
            const isDir = lstatSync(path).isDirectory();

            if (isDir) {
              return foreachFile(callback, path, extensionFilter);
            }

            if (extensionFilter !== null && !filename.endsWith(extensionFilter)) {
              return;
            }
            
            return callback(relative( './src', path));
          }),
        ),
      );
    });
  });
}


// Get build configuration
function getBuildConfig() {
  let config = {};
  const configFilePath = join(__dirname, '/config.json');

  if (existsSync(configFilePath)) {
    config = require('./config.json');
  }

  return {
    'src': '.',
    'dest': '.',
    'flat': false,
    ...config
  };
}

// Build one file
function buildFile({ filePath, buildFilePath }) {
  const options = ['--enable-multi-memory'];
  const command = `wat2wasm ${options.join(' ')} ${filePath} -o ${buildFilePath}`;
  mkdirSync(dirname(buildFilePath), { recursive: true });
  
  return new Promise(resolve => {
    exec(command, (err, stdout, stderr) => {
      if (stderr) {
        resolve({
          success: false,
          error: stderr,
        });
      } else {
        resolve({
          success: true,
          message: stdout,
        });
      }
    });
  });
}

// Sequential files compilation
async function buildFileList(fileList) {
  const results = {
    successes: [],
    fails: [],
  };

  await fileList.reduce((previousPromise, fileBuildObject) => {
    const { targetFilename } = fileBuildObject;

    return previousPromise.then(async () => {
      stdout.write(`  Compiling ${targetFilename}...`);
      const { success, message, error } = await buildFile(fileBuildObject);
      stdout.clearLine(0);
      stdout.cursorTo(0);
      
      if (success) {
        stdout.write(`✅ Compiling ${targetFilename}... \n`);
        message && console.log(message);
        results.successes.push(fileBuildObject);
      } else {
        stdout.write(`❌ Compiling ${targetFilename}... \n`);
        error && console.error(error);
        results.fails.push(fileBuildObject);
      }
    });
  }, Promise.resolve());

  return results;
}

// Watch for files changes
function watchForChanges(callback) {
  let changedFiles = [];
  let deletedFiles = [];
  let eventSet = new Set();
  let ito = null;

  watch(
    sourcePath,
    {
      recursive: true,
    },
    async(eventType, filename) => {
      if (!filename.endsWith(srcExtension)) {
        return;
      }

      const eventKey = eventType + ':' + filename;
      if (eventSet.has(eventKey)) {
        return;
      }

      clearTimeout(ito);
      eventSet.add(eventKey);

      const eventObj = getFileBuildObject(filename);
      
      if (eventType === 'change') {
        changedFiles.push(eventObj);
      } else if (eventType === 'rename' && !existsSync(eventObj.filePath)) {
        deletedFiles.push(eventObj);
      }

      ito = setTimeout(async () => {
        await callback({ changedFiles, deletedFiles });
        eventSet = new Set();
        changedFiles = [];
        deletedFiles = [];
      }, 500);
    }
  );
}

function removeBuildFile(fileBuildObject) {
  return new Promise(resolve => unlink(buildFilePath, err => {
    err && console.error(err);
    console.log('🗑️  Remove', targetFilename);
    resolve();
  }));
}

function getFileBuildObject(filename) {
  const filePath = join(sourcePath, filename);
  const targetFilename = (config.flat !== true
    ? filename.replace(srcExtRegExp, targetExtension)
    : basename(filename)
  ).replace(srcExtRegExp, targetExtension);
  const buildFilePath = join(destPath, targetFilename);

  return {
    filename,
    filePath,
    targetFilename,
    buildFilePath,
  };
}

function removeFilesFormList(list1, ...lists) {
  const list2 = mergeFileLists(...lists);

  return list1.filter(fileObj1 => {
    return !list2.some(fileObj2 => fileObj1.filename === fileObj2.filename);
  });
}

function mergeFileLists(...lists) {
  const added = {};

  return lists
    .flat()
    .reduce((merged, fileObj) => {
      if (!added[fileObj.filename]) {
        added[fileObj.filename] = true;
        merged.push(fileObj);
      }
      return merged;
    }, []);
}

function cleanDestDirectory() {
  rmSync(destPath, { recursive: true, force: true });
}

// Clear console
function clear() {
  const readline = require('readline');
  readline.cursorTo(process.stdout, 0, -2);
  readline.clearScreenDown(process.stdout);
  console.clear();
}


// main
(async function () {
  clear();
  cleanDestDirectory();
  console.time('Compiled in');
  let filesToCompile = await getWatFileList();
  let results = await buildFileList(filesToCompile);
  let unchanged = results.successes;
  let failed = results.fails;
  console.timeEnd('Compiled in');

  if (process.argv.includes('watch')) {
    console.log('\nWaiting for changes in source WAT files...');

    watchForChanges(async ({ changedFiles, deletedFiles }) => {
      clear();
      console.time('\nCompiled in');

      // Removed files
      await Promise.all(
        deletedFiles.map(removeBuildFile)
      );
      
      // Changed files
      filesToCompile = mergeFileLists(
        removeFilesFormList(failed, deletedFiles),
        changedFiles,
      );

      if (filesToCompile.length) {
        changedFiles && console.log(`Change detected in '${changedFiles.map(({ filename }) => filename).join(`', '`)}'...\n`);
        results = await buildFileList(filesToCompile);
        failed = results.fails;
      }

      // Unchanged files
      unchanged = removeFilesFormList(unchanged, deletedFiles, changedFiles);
      unchanged.forEach(({ targetFilename }) => console.log(`♻️  Unchanged ${targetFilename}`));
      unchanged = mergeFileLists(unchanged, results.successes);

      console.timeEnd('\nCompiled in');
      console.log('Waiting for changes in source WAT files...');
    });
  }
})();



module.exports = { foreachSrcFile, getWatFileList, buildFile, buildFileList };