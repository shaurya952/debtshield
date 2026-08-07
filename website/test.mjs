#!/usr/bin/env node
// Zero-dependency checks for the built site: valid structure, working internal
// links, required SEO/meta tags, and no placeholder/secret leakage.

import { build } from "./build.mjs";
import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = dirname(fileURLToPath(import.meta.url));
const outDir = join(root, "dist");

const errors = [];
const err = (m) => errors.push(m);

// Very small HTML helpers (no parser dependency).
const has = (html, re) => re.test(html);

async function run() {
  await build();
  const files = (await readdir(outDir)).filter((f) => f.endsWith(".html"));
  if (files.length === 0) err("no HTML files were generated");

  const linkTargets = new Set(files.map((f) => "/" + f));
  linkTargets.add("/"); // index
  linkTargets.add("/styles.css");
  linkTargets.add("/favicon.svg");
  linkTargets.add("/sitemap.xml");
  linkTargets.add("/robots.txt");

  for (const file of files) {
    const html = await readFile(join(outDir, file), "utf8");
    const where = `[${file}]`;

    if (!has(html, /<html lang="en">/)) err(`${where} missing <html lang="en">`);
    if (!has(html, /<title>[^<]+<\/title>/)) err(`${where} missing <title>`);
    if (!has(html, /<meta name="description" content="[^"]{20,}">/))
      err(`${where} missing/short meta description`);
    if (!has(html, /property="og:title"/)) err(`${where} missing Open Graph title`);
    if (!has(html, /rel="canonical"/)) err(`${where} missing canonical link`);
    if (!has(html, /id="main"/)) err(`${where} missing <main id="main">`);

    const h1s = html.match(/<h1[ >]/g) || [];
    if (h1s.length !== 1) err(`${where} should have exactly one <h1> (found ${h1s.length})`);

    // Unresolved template tokens.
    const leftover = html.match(/\{\{[a-zA-Z]+\}\}/g);
    if (leftover) err(`${where} unresolved token(s): ${[...new Set(leftover)].join(", ")}`);

    // Placeholder / secret leakage.
    for (const bad of ["lorem ipsum", "TODO", "FIXME", "AKIA", "BEGIN PRIVATE KEY"]) {
      if (html.toLowerCase().includes(bad.toLowerCase())) err(`${where} contains "${bad}"`);
    }

    // Any form must have a consent checkbox and a spam honeypot, and must not
    // ask for financial fields.
    if (has(html, /<form/)) {
      if (!has(html, /name="consent"[^>]*required/)) err(`${where} form missing required consent checkbox`);
      if (!has(html, /class="hp"/)) err(`${where} form missing spam honeypot`);
      for (const banned of ["income", "rent", "debt", "salary", "ssn"]) {
        if (has(html, new RegExp(`name="[^"]*${banned}`, "i"))) err(`${where} form asks for financial field "${banned}"`);
      }
    }

    // Internal links resolve to a generated file/asset.
    const hrefs = [...html.matchAll(/href="(\/[^"#?]*)(?:[#?][^"]*)?"/g)].map((m) => m[1]);
    for (const href of hrefs) {
      const target = href === "/" ? "/" : href;
      if (!linkTargets.has(target)) err(`${where} broken internal link: ${href}`);
    }
  }

  if (errors.length) {
    console.error("Website checks FAILED:");
    for (const e of errors) console.error("  - " + e);
    process.exit(1);
  }
  console.log(`Website checks OK — ${files.length} pages, links + meta valid.`);
}

run().catch((e) => {
  console.error("Test run error:", e);
  process.exit(1);
});
