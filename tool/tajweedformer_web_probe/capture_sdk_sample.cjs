// Capture the official sample output and model metadata without a microphone.
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright-core');
if (!process.argv[2] || !process.env.QURANLAB_WEB_KEY) throw new Error('Supply an output path and QURANLAB_WEB_KEY');
const assets = path.resolve(__dirname, '../../assets/tajweedformer_web');
const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname === '/') return res.end('<!doctype html>');
  if (!url.pathname.startsWith('/sdk/')) return res.writeHead(404).end();
  const file = path.resolve(assets, url.pathname.slice(5));
  if (!file.startsWith(assets + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) return res.writeHead(404).end();
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
    const origin = `http://localhost:${server.address().port}`;
    await page.goto(origin);
    await page.addScriptTag({type: 'module', url: `${origin}/sdk/bridge.js`});
    await page.waitForFunction(() => !!window.quranLibraryTajweedFormer);
    const data = await page.evaluate(async key => {
      const sdk = window.quranLibraryTajweedFormer;
      const info = JSON.parse(await sdk.initialize(key));
      try {
        return {info, reference: JSON.parse(await sdk.reference(1, 1)),
          calibration: JSON.parse(sdk.calibration()), sample: JSON.parse(await sdk.sample()),
          diagnosis: JSON.parse(await sdk.diagnose())};
      } finally { await sdk.close(); }
    }, process.env.QURANLAB_WEB_KEY);
    fs.writeFileSync(process.argv[2], JSON.stringify(data));
    console.log('Captured the SDK sample output without microphone input.');
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error.message); server.close(); process.exitCode = 1; });
