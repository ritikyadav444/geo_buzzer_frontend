const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, 'build', 'web');
const PORT = 3030;

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.svg': 'image/svg+xml',
  '.wav': 'audio/wav',
  '.mp3': 'audio/mpeg',
};

http.createServer((req, res) => {
  let url = req.url.split('?')[0];
  if (url === '/') url = '/index.html';

  let filePath = path.join(ROOT, url);
  if (!fs.existsSync(filePath)) {
    filePath = path.join(ROOT, 'index.html');
  }

  const ext = path.extname(filePath);
  res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
  fs.createReadStream(filePath).pipe(res);
}).listen(PORT, () => {
  console.log(`Flutter web app serving on http://localhost:${PORT}`);
});
