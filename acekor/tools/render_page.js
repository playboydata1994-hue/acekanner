// Renders an HTML page to PNG with the pre-installed Chromium (used by brand.py).
// node render_page.js <page.html> <out.png> <width> <height> <transparent 0|1>
const { chromium } = require('playwright');
(async () => {
  const [, , html, out, w, h, transparent] = process.argv;
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 1 });
  await page.goto('file://' + html);
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: out, omitBackground: transparent === '1' });
  await browser.close();
})();
