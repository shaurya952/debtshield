#!/usr/bin/env node
// Tiny zero-dependency static server for local preview of dist/.
// Not for production — deploy dist/ to a static host instead.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join, extname, normalize } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "dist");
const port = process.env.PORT || 4321;

const types = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".svg": "image/svg+xml",
  ".xml": "application/xml",
  ".txt": "text/plain; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
};

createServer(async (req, res) => {
  try {
    let path = decodeURIComponent((req.url || "/").split("?")[0]);
    if (path.endsWith("/")) path += "index.html";
    // Prevent path traversal.
    const filePath = normalize(join(root, path));
    if (!filePath.startsWith(root)) { res.writeHead(403).end("Forbidden"); return; }
    const body = await readFile(filePath);
    res.writeHead(200, { "content-type": types[extname(filePath)] || "application/octet-stream" });
    res.end(body);
  } catch {
    res.writeHead(404, { "content-type": "text/html" }).end("<h1>404</h1>");
  }
}).listen(port, () => console.log(`Serving dist/ at http://localhost:${port}`));
