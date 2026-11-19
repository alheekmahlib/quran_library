// Compare canonical quran-p2g data with the real, verified web SDK reference.
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright-core');

if (!process.argv[2] || !process.env.QURANLAB_WEB_KEY) {
  throw new Error('Supply the prepared JSON path and QURANLAB_WEB_KEY');
}
const rows = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const assets = path.resolve(__dirname, '../../assets/tajweedformer_web');
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname === '/') { res.end('<!doctype html>'); return; }
  if (!url.pathname.startsWith('/sdk/')) { res.writeHead(404).end(); return; }
  const file = path.resolve(assets, url.pathname.slice('/sdk/'.length));
  if (!file.startsWith(assets + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    res.writeHead(404).end(); return;
  }
  res.setHeader('Content-Type', file.endsWith('.js') ? 'text/javascript' : file.endsWith('.wasm') ? 'application/wasm' : 'application/octet-stream');
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const options = {headless: true};
  if (process.env.CHROME_EXECUTABLE) options.executablePath = process.env.CHROME_EXECUTABLE;
  const browser = await chromium.launch(options);
  try {
    const page = await browser.newPage();
    await page.goto(`http://localhost:${server.address().port}`);
    await page.addScriptTag({type: 'module', url: '/sdk/bridge.js'});
    await page.waitForFunction(() => !!window.quranLibraryTajweedFormer);
    const result = await page.evaluate(async ({rows, key, collect}) => {
      const sdk = window.quranLibraryTajweedFormer;
      const info = JSON.parse(await sdk.initialize(key));
      const mismatches = {tokens: [], wordIndices: [], displayedWordCounts: []};
      const references = {};
      try {
        for (const row of rows) {
          const ref = JSON.parse(await sdk.reference(row.s, row.a));
          if (collect) references[`${row.s}:${row.a}`] = ref;
          const tokenIndices = ref.units.map((token, index) => token === info.wordBar ? -1 : index).filter(i => i >= 0);
          const tokens = tokenIndices.map(i => info.tokens[ref.units[i]]);
          const words = tokenIndices.map(i => ref.words[i]);
          const verse = `${row.s}:${row.a}`;
          if (JSON.stringify(tokens) !== JSON.stringify(row.expected)) mismatches.tokens.push(verse);
          if (JSON.stringify(words) !== JSON.stringify(row.expectedWords)) mismatches.wordIndices.push(verse);
          if (ref.wordCount !== row.words) mismatches.displayedWordCounts.push(verse);
        }
        return {mismatches, info: collect ? info : null, references,
          calibration: collect ? JSON.parse(sdk.calibration()) : null};
      } finally { await sdk.close(); }
    }, {rows, key: process.env.QURANLAB_WEB_KEY, collect: !!process.argv[3]});
    for (const [kind, verses] of Object.entries(result.mismatches)) {
      console.log(`${kind}: ${verses.length} mismatches out of ${rows.length}`);
    }
    if (result.mismatches.tokens.length || result.mismatches.wordIndices.length) process.exitCode = 1;
    if (process.argv[3]) {
      fs.writeFileSync(process.argv[3], JSON.stringify({info: result.info, references: result.references, calibration: result.calibration}));
    }
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error.message); server.close(); process.exitCode = 1; });
