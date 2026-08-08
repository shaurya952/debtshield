#!/usr/bin/env node
// Zero-dependency static site generator for the DebtShield website.
// Reads src/layout.html + src/pages/<slug>.html, injects shared metadata/nav,
// and writes static HTML to dist/. Also copies styles/public and emits
// sitemap.xml + robots.txt. No third-party dependencies (Node stdlib only).

import { readFile, writeFile, mkdir, readdir, copyFile, rm } from "node:fs/promises";
import { existsSync } from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { pages } from "./src/pages.mjs";

const root = dirname(fileURLToPath(import.meta.url));
const srcDir = join(root, "src");
const outDir = join(root, "dist");

// Base URL. Defaults to the live Cloudflare Pages URL so canonical/OG/sitemap
// links are correct out of the box; override with the SITE_URL env var when a
// custom domain is set (documented in README).
const SITE_URL = (process.env.SITE_URL || "https://debtshield-web.pages.dev").replace(/\/$/, "");

// Form endpoint (Formspree). Defaults to the live form so the waitlist/pilot/
// reviewer forms work out of the box; override with the FORM_ENDPOINT env var to
// point at a different provider. Keep this in sync with the default in test.mjs.
const FORM_ENDPOINT = process.env.FORM_ENDPOINT || "https://formspree.io/f/xwlevvgy";
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

function render(layout, page, content, stylesHref) {
  // Insert page content first, then resolve every token across the whole
  // document — so tokens inside page content (e.g. form fields) resolve too.
  return layout
    .replace("{{content}}", content)
    .replaceAll("{{stylesHref}}", stylesHref)
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

  // Cache-bust the stylesheet: name it styles.<hash>.css so every content change
  // gets a fresh URL. Browsers then never serve a stale stylesheet, and the
  // hashed file can be cached immutably (see _headers below).
  const cssSource = await readFile(join(srcDir, "styles.css"), "utf8");
  const cssHash = createHash("sha256").update(cssSource).digest("hex").slice(0, 8);
  const cssName = `styles.${cssHash}.css`;
  const stylesHref = `/${cssName}`;

  for (const page of pages) {
    const contentPath = join(srcDir, "pages", `${page.slug}.html`);
    if (!existsSync(contentPath)) {
      throw new Error(`Missing content for page "${page.slug}" (${contentPath})`);
    }
    const content = await readFile(contentPath, "utf8");
    const html = render(layout, page, content, stylesHref);
    await writeFile(join(outDir, fileFor(page.slug)), html, "utf8");
  }

  // Static assets. The stylesheet is written under its content-hashed name.
  await writeFile(join(outDir, cssName), cssSource, "utf8");
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

  // Security headers for hosts that honor a `_headers` file (Netlify, Cloudflare
  // Pages). The site ships no JS, so the CSP can be strict; `form-action` allows
  // the configured form endpoint's origin so the waitlist/pilot/reviewer forms
  // can POST. (Vercel uses vercel.json instead — kept in sync.)
  let formOrigin = "";
  try { if (FORM_CONFIGURED) formOrigin = " " + new URL(FORM_ENDPOINT).origin; } catch { /* leave as 'self' only */ }
  const csp = [
    "default-src 'none'",
    "base-uri 'self'",
    "script-src 'none'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data:",
    "font-src 'self'",
    `form-action 'self'${formOrigin}`,
    "frame-ancestors 'none'",
    "object-src 'none'",
    "connect-src 'self'",
    "manifest-src 'self'",
    "upgrade-insecure-requests",
  ].join("; ");
  const headers = `/*
  Content-Security-Policy: ${csp}
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  X-Frame-Options: DENY
  Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
  Permissions-Policy: camera=(), microphone=(), geolocation=(), browsing-topics=()
  Cross-Origin-Opener-Policy: same-origin

/styles.*.css
  Cache-Control: public, max-age=31536000, immutable
`;
  await writeFile(join(outDir, "_headers"), headers, "utf8");

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
