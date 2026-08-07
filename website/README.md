# DebtShield website

The marketing + trust website for DebtShield. Static, fast, accessible, and
**zero-dependency**.

## Why this stack
A privacy-first product deserves a privacy-first site. Instead of a framework
with a large dependency tree, this is a tiny static generator built on the Node
standard library only:

- **No third-party dependencies** — nothing to audit for trackers or supply-chain
  risk, and it builds offline (aligns with the project's "no unnecessary
  dependencies" rule).
- **No client-side tracking, no cookies, no analytics.**
- **Portable** — the output is plain HTML/CSS you can host anywhere.
- **Easy to migrate later** — if the team wants MDX/components, the content is
  plain HTML and moves to Astro/Eleventy without lock-in.

## Structure
```
website/
  build.mjs        generator (layout + pages → dist/)
  test.mjs         checks: links resolve, meta tags present, no placeholders
  serve.mjs        tiny local preview server (dev only)
  src/
    layout.html    shared shell (head, nav, footer, SEO/OG)
    styles.css     design system (light/dark, WCAG-AA)
    pages.mjs      the site map (title, description, nav)
    pages/*.html   per-page content fragments
  public/          static assets copied as-is (favicon.svg)
  dist/            build output (gitignored)
```

## Develop
```bash
cd website
npm run build      # → dist/
npm test           # build + validate links/meta
npm start          # build, then serve dist/ at http://localhost:4321
```
No install step is required (there are no dependencies). Node 18+.

## Configuration
- `SITE_URL` — absolute base URL used for canonical links, Open Graph, and the
  sitemap. Defaults to a placeholder. Set it at build/deploy time:
  ```bash
  SITE_URL=https://your-domain.example npm run build
  ```
- `FORM_ENDPOINT` — where the waitlist / pilot / reviewer forms POST. Until it's
  set, the forms render in a clearly-labeled "not connected" state and submit
  nowhere. Set it to a privacy-conscious provider or serverless URL:
  ```bash
  FORM_ENDPOINT=https://formspree.io/f/xxxx SITE_URL=https://your-domain npm run build
  ```
  Options and the data policy (fields, retention, deletion, spam, consent,
  security) are documented in `../docs/WAITLIST_DATA_POLICY.md`. Whatever you
  choose, ensure it rejects submissions where the hidden `company_website`
  honeypot field is filled.

## Deploy
The site is fully static — deploy `dist/` to any static host. Deploy config is
wired for the three mainstream hosts; **set the project root/base to `website`**,
build command `node build.mjs`, output `dist`, Node 20.

Set env vars on the host: `SITE_URL` (required for correct canonical/OG/sitemap)
and, when ready, `FORM_ENDPOINT` (see Configuration above).

- **Netlify** — `netlify.toml` is included. In the UI set **Base directory** =
  `website`. Security headers + the SPA-less 404 come from the generated
  `dist/_headers` and `dist/404.html`.
- **Cloudflare Pages** — root directory `website`, build `node build.mjs`,
  output `dist`. Cloudflare honors `dist/_headers` too.
- **Vercel** — `vercel.json` is included (set the project **Root Directory** to
  `website`). Headers are defined there (Vercel ignores `_headers`); its CSP
  uses `form-action 'self' https:` — tighten it to your exact `FORM_ENDPOINT`
  origin if you prefer.

### Security headers
`node build.mjs` emits `dist/_headers` (Netlify/Cloudflare) with a strict,
JS-free **Content-Security-Policy** (`script-src 'none'`; `form-action` allows
only `self` + the configured `FORM_ENDPOINT` origin), plus HSTS, nosniff,
`X-Frame-Options: DENY`, a locked-down `Permissions-Policy`, and COOP. Vercel
gets the equivalent via `vercel.json`. Verify after deploy with
[securityheaders.com](https://securityheaders.com) or
`curl -sI https://your-domain | grep -i content-security-policy`.

## Guarantees / non-goals
- No database and no server code (a form, when added, will post to a
  privacy-conscious provider or serverless endpoint — documented then).
- No secrets are committed; there are none to commit.
- Legal pages (`privacy-policy`, `terms`) are **drafts for discussion** and must
  be reviewed by an attorney before launch.
- Contact addresses are intentionally omitted until real; do not invent them.
