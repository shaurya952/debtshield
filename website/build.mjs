#!/usr/bin/env node
// Zero-dependency static site generator for the DebtShield website.
// Reads src/layout.html + src/pages/<slug>.html, injects shared metadata/nav,
// and writes static HTML to dist/. Also copies styles/public and emits
// sitemap.xml + robots.txt. No third-party dependencies (Node stdlib only).

import { readFile, writeFile, mkdir, readdir, copyFile, rm } from "node:fs/promises";
import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { pages } from "./src/pages.mjs";

const root = dirname(fileURLToPath(import.meta.url));
const srcDir = join(root, "src");
const outDir = join(root, "dist");

// Base URL is set at deploy time. Placeholder by default (documented in README).
const SITE_URL = (process.env.SITE_URL || "https://debtshield.example").replace(/\/$/, "");

// Form endpoint (a privacy-conscious provider or serverless URL) is set at
// deploy time. Until then, forms render in a clearly-labeled "not connected"
// state so nothing silently posts to nowhere.
const FORM_ENDPOINT = process.env.FORM_ENDPOINT || "";
const FORM_CONFIGURED = FORM_ENDPOINT.length > 0;
const FORM_NOTICE = FORM_CONFIGURED
  ? ""
  : `<div class="callout"><p style="margin:0"><strong>This form isn't connected yet.</strong> Submissions activate once a form endpoint is configured at deploy time — see the website README. Your details are never sent anywhere until then.</p></div>`;

const canonicalFor = (slug) => (slug === "index" ? "" : `${slug}.html`);
const fileFor = (slug) => `${slug}.html`;

function navHtml(currentSlug) {
  return pages
    .filter((p) => p.nav)
    .map((p) => {
      const href = "/" + canonicalFor(p.slug);
      const current = p.slug === currentSlug ? ' aria-current="page"' : "";
      return `<a href="${href}"${current}>${p.navLabel}</a>`;
    })
    .join("\n          ");
}

function render(layout, page, content) {
  // Insert page content first, then resolve every token across the whole
  // document — so tokens inside page content (e.g. form fields) resolve too.
  return layout
    .replace("{{content}}", content)
    .replaceAll("{{title}}", page.title)
    .replaceAll("{{description}}", page.description)
    .replaceAll("{{canonical}}", canonicalFor(page.slug))
    .replaceAll("{{siteUrl}}", SITE_URL)
    .replaceAll("{{year}}", String(new Date().getFullYear()))
    .replaceAll("{{nav}}", navHtml(page.slug))
    .replaceAll("{{formAction}}", FORM_CONFIGURED ? FORM_ENDPOINT : "#")
    .replaceAll("{{formMethod}}", FORM_CONFIGURED ? "post" : "get")
    .replaceAll("{{formDisabled}}", FORM_CONFIGURED ? "" : "disabled")
    .replaceAll("{{formNotice}}", FORM_NOTICE);
}

async function copyDir(from, to) {
  if (!existsSync(from)) return;
  await mkdir(to, { recursive: true });
  for (const entry of await readdir(from, { withFileTypes: true })) {
    const s = join(from, entry.name);
    const d = join(to, entry.name);
    if (entry.isDirectory()) await copyDir(s, d);
    else await copyFile(s, d);
  }
}

export async function build() {
  await rm(outDir, { recursive: true, force: true });
  await mkdir(outDir, { recursive: true });

  const layout = await readFile(join(srcDir, "layout.html"), "utf8");

  for (const page of pages) {
    const contentPath = join(srcDir, "pages", `${page.slug}.html`);
    if (!existsSync(contentPath)) {
      throw new Error(`Missing content for page "${page.slug}" (${contentPath})`);
    }
    const content = await readFile(contentPath, "utf8");
    const html = render(layout, page, content);
    await writeFile(join(outDir, fileFor(page.slug)), html, "utf8");
  }

  // Static assets.
  await copyFile(join(srcDir, "styles.css"), join(outDir, "styles.css"));
  await copyDir(join(root, "public"), outDir);

  // Sitemap.
  const urls = pages
    .map((p) => `  <url><loc>${SITE_URL}/${canonicalFor(p.slug)}</loc></url>`)
    .join("\n");
  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>\n`;
  await writeFile(join(outDir, "sitemap.xml"), sitemap, "utf8");

  // robots.txt (Sitemap URL tracks SITE_URL).
  const robots = `User-agent: *\nAllow: /\n\nSitemap: ${SITE_URL}/sitemap.xml\n`;
  await writeFile(join(outDir, "robots.txt"), robots, "utf8");

  return pages.length;
}

// Run when invoked directly.
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  build()
    .then((n) => console.log(`Built ${n} pages → dist/  (SITE_URL=${SITE_URL})`))
    .catch((e) => {
      console.error("Build failed:", e.message);
      process.exit(1);
    });
}
