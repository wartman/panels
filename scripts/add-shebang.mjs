import fs from 'fs/promises';

// There's certainly a better way to do this, but for the moment...
fs.readFile('bin/panels.js', { encoding: "utf-8" })
  .then(file => fs.writeFile('bin/panels.js', '#!/usr/bin/env node\n' + file))
