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

// Programmatic SEO pages, built from the bundled public data (BLS wages + Census
// rent). Returns the list of relative URLs written, for the sitemap.
async function buildSeoPages(layout, stylesHref) {
  const dataPath = join(srcDir, "seo-data.json");
  if (!existsSync(dataPath)) return [];
  const data = JSON.parse(await readFile(dataPath, "utf8"));
  const { names, wages, emp, stateRent } = data;
  const ratio = data.takeHomeRatio || 0.78;
  const taxPct = Math.round((1 - ratio) * 100);
  const urls = [];

  const slug = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
  const money = (n) => "$" + Math.round(n).toLocaleString("en-US");
  const th = (annual) => Math.round((annual / 12) * ratio);
  const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

  const jobCodes = Object.keys(names).filter((c) => wages[c]).sort((a, b) => names[a].localeCompare(names[b]));
  const jobSlug = Object.fromEntries(jobCodes.map((c) => [c, slug(names[c])]));
  const states = Object.keys(stateRent).sort();
  const stateSlug = Object.fromEntries(states.map((s) => [s, slug(s)]));

  await mkdir(join(outDir, "jobs"), { recursive: true });
  await mkdir(join(outDir, "cost-of-living"), { recursive: true });

  const write = async (relPath, page, content) => {
    await writeFile(join(outDir, relPath), render(layout, page, content, stylesHref), "utf8");
    urls.push(relPath);
  };

  for (const c of jobCodes) {
    const name = names[c];
    const rows = states
      .filter((s) => wages[c][s] && stateRent[s])
      .map((s) => { const t = th(wages[c][s]); return { s, t, r: stateRent[s], left: t - stateRent[s], pct: Math.round((stateRent[s] / t) * 100) }; })
      .sort((a, b) => b.left - a.left);
    if (!rows.length) continue;
    const best = rows[0], worst = rows[rows.length - 1];
    const table = rows.map((row) => `<tr><td><a href="/cost-of-living/${stateSlug[row.s]}.html">${esc(row.s)}</a></td><td>${money(row.t)}/mo</td><td>${money(row.r)}/mo</td><td>${row.pct}%</td></tr>`).join("");
    const content = `<div class="wrap"><section>
        <p class="eyebrow">Pay vs cost of living</p>
        <h1>How far does a ${esc(name)}'s pay go, state by state?</h1>
        <p class="lead narrow">A ${esc(name)}'s pay leaves the most room in <strong>${esc(best.s)}</strong> — about ${money(best.t)}/mo take-home against ${money(best.r)}/mo typical rent — and the least in <strong>${esc(worst.s)}</strong>.</p>
        <div class="table-wrap"><table><thead><tr><th>State</th><th>Est. take-home</th><th>Typical rent</th><th>Rent share</th></tr></thead><tbody>${table}</tbody></table></div>
        <p class="muted">Take-home is that state's BLS OEWS 2023 median wage after a rough ~${taxPct}% tax estimate — a ballpark, not a real paycheck. Rent is population-weighted Census gross rent (utilities included). Neither includes state taxes, insurance, or the cost of moving.</p>
        <p><a class="btn" href="/waitlist.html">See your own numbers in Headroom</a></p>
      </section></div>`;
    await write(`jobs/${jobSlug[c]}.html`, {
      slug: `jobs/${jobSlug[c]}`,
      title: `${name} pay vs cost of living by state`,
      description: `Where a ${name}'s pay goes furthest after rent — a state-by-state comparison from public BLS wage and Census rent data.`,
    }, content);
  }

  for (const s of states) {
    const r = stateRent[s];
    const rows = jobCodes
      .filter((c) => wages[c][s])
      .map((c) => { const t = th(wages[c][s]); return { c, name: names[c], t, pct: Math.round((r / t) * 100) }; })
      .sort((a, b) => b.t - a.t);
    if (!rows.length) continue;
    const table = rows.map((row) => `<tr><td><a href="/jobs/${jobSlug[row.c]}.html">${esc(row.name)}</a></td><td>${money(row.t)}/mo</td><td>${row.pct}%</td></tr>`).join("");
    const content = `<div class="wrap"><section>
        <p class="eyebrow">Cost of living</p>
        <h1>Cost of living in ${esc(s)}: what jobs pay vs rent</h1>
        <p class="lead narrow">Typical rent in ${esc(s)} is about <strong>${money(r)}/mo</strong> (population-weighted Census gross rent, utilities included). Here's how ${rows.length} common jobs' estimated take-home pay compares.</p>
        <div class="table-wrap"><table><thead><tr><th>Job</th><th>Est. take-home</th><th>Rent share</th></tr></thead><tbody>${table}</tbody></table></div>
        <p class="muted">Pay is BLS OEWS 2023 state median wages after a rough ~${taxPct}% tax estimate — a ballpark, not a real paycheck. It doesn't include state taxes, insurance, transport, or the cost of moving.</p>
        <p><a class="btn" href="/waitlist.html">See your own numbers in Headroom</a></p>
      </section></div>`;
    await write(`cost-of-living/${stateSlug[s]}.html`, {
      slug: `cost-of-living/${stateSlug[s]}`,
      title: `Cost of living in ${s}: pay vs rent`,
      description: `What common jobs pay in ${s} against its typical rent — from public BLS wage and Census rent data.`,
    }, content);
  }

  const jobLinks = jobCodes.map((c) => `<li><a href="/jobs/${jobSlug[c]}.html">${esc(names[c])}</a></li>`).join("");
  await write("jobs.html",
    { slug: "jobs", title: "Pay by job, state by state", description: "Browse how far each job's pay goes across U.S. states, against local rent." },
    `<div class="wrap"><section><p class="eyebrow">Explore</p><h1>How far does your job's pay go?</h1><p class="lead narrow">Pick a job to see where its pay stretches furthest after rent.</p><ul class="link-list">${jobLinks}</ul></section></div>`);
  const stateLinks = states.map((s) => `<li><a href="/cost-of-living/${stateSlug[s]}.html">${esc(s)}</a></li>`).join("");
  await write("cost-of-living.html",
    { slug: "cost-of-living", title: "Cost of living by state", description: "Typical rent and what jobs pay in each U.S. state." },
    `<div class="wrap"><section><p class="eyebrow">Explore</p><h1>Cost of living by state</h1><p class="lead narrow">Pick a state to see its typical rent and what common jobs pay there.</p><ul class="link-list">${stateLinks}</ul></section></div>`);

  return urls;
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

  // Programmatic SEO: real, substantial hub pages built from the bundled public
  // data — one per job (its pay across every state vs rent) and one per state (what
  // jobs pay there vs its rent), richly cross-linked. Not thin doorway pages: each
  // carries a full data table and honest caveats.
  const seoUrls = await buildSeoPages(layout, stylesHref);

  // Static assets. The stylesheet is written under its content-hashed name.
  await writeFile(join(outDir, cssName), cssSource, "utf8");
  await copyDir(join(root, "public"), outDir);

  // Sitemap.
  const urls = pages
    .map((p) => `  <url><loc>${SITE_URL}/${canonicalFor(p.slug)}</loc></url>`)
    .concat(seoUrls.map((u) => `  <url><loc>${SITE_URL}/${u}</loc></url>`))
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
