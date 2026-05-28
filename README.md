# octogram-marketing

Static marketing site for [Octogram](https://octogram.app) — a word-finding game for iOS and Android.

Hosted on Cloudflare Pages. No build step required; the root directory is the deploy artifact.

## Local dev

```bash
npm install
npm run dev       # serves at http://localhost:3000
```

## Deploy to Cloudflare Pages

### Option A — Git integration (recommended)

1. Push this repo to GitHub.
2. Go to [Cloudflare Pages](https://pages.cloudflare.com) → **Create a project** → **Connect to Git**.
3. Select the `octogram-marketing` repo.
4. Set **Build command** to *(empty)* and **Build output directory** to `/` (root).
5. Cloudflare will deploy on every push to `main`.

### Option B — Wrangler CLI

```bash
npm run deploy
```

This calls `wrangler pages deploy` directly.

## Custom domain

In the Cloudflare Pages dashboard:  
**Settings → Custom domains → Add a domain** → enter your domain.

Cloudflare will automatically provision a TLS certificate and update DNS.

## Files

| File | Purpose |
|------|---------|
| `index.html` | Full marketing landing page |
| `_headers` | Cloudflare Pages HTTP response headers |
| `_redirects` | Catch-all SPA redirect rule |
| `wrangler.toml` | Wrangler CLI config |
| `favicon.png` | Tab icon (copy from the main app's `assets/images/favicon.png`) |
