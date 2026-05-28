import { chromium } from 'playwright';
import { resolve } from 'node:path';

const [, , inputArg, outputArg, widthArg, heightArg] = process.argv;
if (!inputArg || !outputArg) {
  console.error('usage: node _render.mjs <input.html|url> <output.png> [width] [height]');
  process.exit(1);
}

const width = parseInt(widthArg || '1200', 10);
const height = parseInt(heightArg || '630', 10);
const target = inputArg.startsWith('http') ? inputArg : 'file://' + resolve(inputArg);
const out = resolve(outputArg);

const browser = await chromium.launch();
const ctx = await browser.newContext({
  viewport: { width, height },
  deviceScaleFactor: 2,
});
const page = await ctx.newPage();
await page.goto(target, { waitUntil: 'networkidle' });
await page.waitForTimeout(800);
await page.screenshot({ path: out, fullPage: false });
await browser.close();
console.log('wrote', out);
