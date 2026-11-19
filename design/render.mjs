// Render design mockups and launcher icon from the HTML sources.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { launch, connect, sleep } from './tools/cdp.mjs';

const ROOT = path.resolve('.');
const OUT = path.join(ROOT, 'design');
const PORT = 9333;

const shots = [
  { page: 'screens', selector: '#s-auth', file: 'mockups/01-auth.png', scale: 4 },
  { page: 'screens', selector: '#s-home', file: 'mockups/02-home.png', scale: 4 },
  { page: 'screens', selector: '#s-schedule', file: 'mockups/03-schedule.png', scale: 4 },
  { page: 'screens', selector: '#s-visits', file: 'mockups/04-visits.png', scale: 4 },
  { page: 'screens', selector: '#s-purchases', file: 'mockups/05-purchases.png', scale: 4 },
  { page: 'screens', selector: '#s-bookings', file: 'mockups/06-bookings.png', scale: 4 },
  { page: 'screens', selector: '#s-menu', file: 'mockups/07-theme-menu.png', scale: 4 },
  { page: 'screens', selector: '#s-theme', file: 'mockups/08-theme-dialog.png', scale: 4 },
  { page: 'screens', selector: '#s-home-dark', file: 'mockups/09-home-dark.png', scale: 4 },
  { page: 'screens', selector: '#s-home-pink', file: 'mockups/10-home-pink.png', scale: 4 },
  { page: 'screens', selector: '#s-home-long', file: 'mockups/11-home-full.png', scale: 4 },
  { page: 'fab', selector: '#fab-spec', file: 'mockups/12-fab-spec.png', scale: 2 },
  { page: 'icons', selector: '#icon-1024', file: 'icon/icon-2048.png', scale: 2 },
  { page: 'icons', selector: '#icon-1024', file: 'icon/icon-1024.png', scale: 1 },
  { page: 'icons', selector: '#icon-fg', file: 'icon/adaptive-foreground-432.png', scale: 1 },
  { page: 'icons', selector: '#icon-mono', file: 'icon/monochrome-432.png', scale: 1 },
];

const { proc, port } = await launch({ port: PORT });
try {
  const cdp = await connect(port);
  await cdp.send('Page.enable');
  await cdp.send('Runtime.enable');
  await cdp.send('Emulation.setDeviceMetricsOverride', { width: 1200, height: 1000, deviceScaleFactor: 1, mobile: false });

  let currentPage = null;
  for (const shot of shots) {
    if (currentPage !== shot.page) {
      currentPage = shot.page;
      const url = pathToFileURL(path.join(ROOT, 'design', 'src', shot.page + '.html')).href;
      await cdp.send('Page.navigate', { url });
      await sleep(1200);
      await cdp.evaluate('document.fonts.ready.then(() => true)');
      await sleep(900);
      if (shot.page === 'screens') await cdp.evaluate('window.__ready === true');
      else await cdp.send('Emulation.setDefaultBackgroundColorOverride', { color: { r: 0, g: 0, b: 0, a: 0 } });
    }
    const rect = await cdp.evaluate(`(() => {
      const el = document.querySelector(${JSON.stringify(shot.selector)});
      const r = el.getBoundingClientRect();
      return { x: r.x + scrollX, y: r.y + scrollY, w: r.width, h: r.height };
    })()`);
    const result = await cdp.send('Page.captureScreenshot', {
      format: 'png',
      captureBeyondViewport: true,
      clip: { x: rect.x, y: rect.y, width: rect.w, height: rect.h, scale: shot.scale },
    });
    const file = path.join(OUT, shot.file);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, Buffer.from(result.data, 'base64'));
    console.log(`${shot.file}  ${Math.round(rect.w * shot.scale)}x${Math.round(rect.h * shot.scale)}`);
  }
  cdp.close();
} finally {
  proc.kill();
}
