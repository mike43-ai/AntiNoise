// Render each .frame in screenshots.html to a 1290x2796 PNG (App Store 6.7").
// Run from a dir whose node_modules has playwright (e.g. ../../../blog-images):
//   node ../docs/social-assets/app-store/render.mjs
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { mkdirSync } from 'fs';

// Resolve playwright from the repo's existing install (passed as argv[2]).
const require = createRequire(process.argv[2] || process.cwd() + '/');
const { chromium } = require('playwright');

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, 'png');
mkdirSync(outDir, { recursive: true });

const ids = ['s1', 's2', 's3', 's4', 's5'];
const names = {
  s1: '01-daily-knowledge',
  s2: '02-layered-flashcards',
  s3: '03-feynman-summary',
  s4: '04-capture-anywhere',
  s5: '05-private-no-api-key',
};

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1290, height: 2796 }, deviceScaleFactor: 1 });
await page.goto('file://' + join(here, 'screenshots.html'), { waitUntil: 'networkidle' });

for (const id of ids) {
  const el = await page.$('#' + id);
  const out = join(outDir, names[id] + '.png');
  await el.screenshot({ path: out });
  console.log('wrote', out);
}

await browser.close();
console.log('done');
