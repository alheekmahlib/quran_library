// Run the official web SDK locally; only public benchmark audio is read.
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright-core');

const dir = path.resolve(process.argv[2] || '');
const key = process.env.QURANLAB_WEB_KEY;
if (!process.argv[2] || !key) throw new Error('Supply a benchmark directory and QURANLAB_WEB_KEY');
const cases = JSON.parse(fs.readFileSync(path.join(dir, 'cases.json'), 'utf8'));
const assets = path.resolve(__dirname, '../../assets/tajweedformer_web');
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  let file;
  if (url.pathname === '/') { res.end('<!doctype html><meta charset="utf-8">'); return; }
  if (/^\/clip\d+\.f32$/.test(url.pathname)) file = path.join(dir, url.pathname.slice(1));
  else if (url.pathname.startsWith('/sdk/')) {
    file = path.resolve(assets, url.pathname.slice('/sdk/'.length));
    if (!file.startsWith(assets + path.sep)) file = null;
  }
  if (!file || !fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404).end(); return; }
  const extension = path.extname(file);
  res.setHeader('Content-Type', extension === '.js' ? 'text/javascript' : extension === '.wasm' ? 'application/wasm' : 'application/octet-stream');
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = `http://localhost:${server.address().port}`;
  const options = {headless: true};
  if (process.env.CHROME_EXECUTABLE) options.executablePath = process.env.CHROME_EXECUTABLE;
  const browser = await chromium.launch(options);
  try {
    const page = await browser.newPage();
    await page.goto(origin);
    await page.addScriptTag({type: 'module', url: `${origin}/sdk/bridge.js`});
    await page.waitForFunction(() => !!window.quranLibraryTajweedFormer);
    const capture = process.argv[3] === '--capture-heads';
    const output = await page.evaluate(async ({key, cases, capture}) => {
      const sdk = window.quranLibraryTajweedFormer;
      const info = JSON.parse(await sdk.initialize(key));
      try {
        const results = [];
        const captures = [];
        for (let i = 0; i < cases.length; i++) {
          const data = await (await fetch(`/clip${i}.f32`)).arrayBuffer();
          const started = performance.now();
          const result = JSON.parse(await sdk.recognize(new Float32Array(data)));
          results.push({text: result.text, seconds: (performance.now() - started) / 1000});
          if (capture) {
            const [surah, ayah] = cases[i].ayah.split(':').map(Number);
            captures.push({ayah: cases[i].ayah, reference: JSON.parse(await sdk.reference(surah, ayah)), sample: result});
          }
        }
        return {results, captures, info: capture ? info : null,
          calibration: capture ? JSON.parse(sdk.calibration()) : null};
      } finally { await sdk.close(); }
    }, {key, cases, capture});
    fs.writeFileSync(path.join(dir, 'hypotheses.json'), JSON.stringify(output.results));
    if (capture) fs.writeFileSync(path.join(dir, 'sdk-captures.json'), JSON.stringify(output));
    console.log(`Decoded ${output.results.length} clips; hypotheses saved locally.`);
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error.message); server.close(); process.exitCode = 1; });
