import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { launch, connect, sleep } from './tools/cdp.mjs';

const ROOT = path.resolve('.');
const OUT = path.join(ROOT, 'design', 'sketches', 'bonus-sketch.png');
const PORT = 9336;

const { proc, port } = await launch({ port: PORT });
try {
  const cdp = await connect(port);
  await cdp.send('Page.enable');
  await cdp.send('Runtime.enable');
  await cdp.send('Emulation.setDeviceMetricsOverride', {
    width: 1320,
    height: 1000,
    deviceScaleFactor: 1,
    mobile: false,
  });
  const url = pathToFileURL(
    path.join(ROOT, 'design', 'src', 'bonus-sketch.html'),
  ).href;
  await cdp.send('Page.navigate', { url });
  await sleep(1200);
  await cdp.evaluate('document.fonts.ready.then(() => true)');
  await sleep(900);
  const size = await cdp.evaluate(`(() => ({
    w: document.body.scrollWidth,
    h: document.body.scrollHeight
  }))()`);
  const result = await cdp.send('Page.captureScreenshot', {
    format: 'png',
    captureBeyondViewport: true,
    clip: { x: 0, y: 0, width: size.w, height: size.h, scale: 2 },
  });
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, Buffer.from(result.data, 'base64'));
  console.log(`${OUT} ${size.w * 2}x${size.h * 2}`);
  cdp.close();
} finally {
  proc.kill();
}
