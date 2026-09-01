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

  // Walk the built tree so generated SEO pages (jobs/*, cost-of-living/*) count as
  // both pages to validate and valid link targets.
  async function walkHtml(dir, prefix = "") {
    const out = [];
    for (const entry of await readdir(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) out.push(...(await walkHtml(join(dir, entry.name), prefix + entry.name + "/")));
      else if (entry.name.endsWith(".html")) out.push(prefix + entry.name);
    }
    return out;
  }
  const files = await walkHtml(outDir);
  if (files.length === 0) err("no HTML files were generated");

  const linkTargets = new Set(files.map((f) => "/" + f));
  linkTargets.add("/"); // index
  // The stylesheet is emitted under a content-hashed name (styles.<hash>.css);
  // register whatever CSS files the build produced.
  for (const f of await readdir(outDir)) {
    if (f.endsWith(".css")) linkTargets.add("/" + f);
  }
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

  // Security headers — a regression here silently weakens the deployed site.
  // dist/_headers (Netlify/Cloudflare) is generated from the same build; its CSP
  // adapts to FORM_ENDPOINT, so we assert accordingly. vercel.json must keep the
  // equivalent headers so the two hosts don't drift.
  {
    const headersText = await readFile(join(outDir, "_headers"), "utf8");
    const needHeaders = [
      "Content-Security-Policy:",
      "X-Content-Type-Options: nosniff",
      "X-Frame-Options: DENY",
      "Strict-Transport-Security:",
      "Referrer-Policy:",
      "Permissions-Policy:",
      "Cross-Origin-Opener-Policy: same-origin",
    ];
    for (const n of needHeaders) if (!headersText.includes(n)) err(`[_headers] missing "${n}"`);

    const needCsp = [
      "default-src 'none'",
      "script-src 'none'",
      "frame-ancestors 'none'",
      "object-src 'none'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data:",
    ];
    for (const d of needCsp) if (!headersText.includes(d)) err(`[_headers] CSP missing "${d}"`);

    // Mirror build.mjs's default so the CSP form-action origin is asserted for
    // the live Formspree endpoint (keep this string in sync with build.mjs).
    const endpoint = process.env.FORM_ENDPOINT || "https://formspree.io/f/xwlevvgy";
    if (endpoint) {
      let origin = "";
      try { origin = new URL(endpoint).origin; } catch { /* invalid URL → treated as none */ }
      if (!origin || !headersText.includes(`form-action 'self' ${origin}`)) {
        err(`[_headers] CSP form-action should include the FORM_ENDPOINT origin (${origin || endpoint})`);
      }
    } else if (!headersText.includes("form-action 'self';")) {
      err("[_headers] CSP form-action should be 'self' when no FORM_ENDPOINT is set");
    }

    // vercel.json parity (valid JSON + core headers present).
    try {
      const vercel = JSON.parse(await readFile(join(root, "vercel.json"), "utf8"));
      const flat = JSON.stringify(vercel);
      for (const n of ["Content-Security-Policy", "Strict-Transport-Security", "X-Frame-Options"]) {
        if (!flat.includes(n)) err(`[vercel.json] missing "${n}" header`);
      }
    } catch (e) {
      err(`[vercel.json] invalid or unreadable: ${e.message}`);
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
