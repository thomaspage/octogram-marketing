#!/usr/bin/env bash
#
# Build the Octogram web app (local-only, no Supabase) and stage it under
# ./play for Cloudflare Pages, served at https://octogram.app/play.
#
# This exists because three things have to happen together, and forgetting any
# one of them breaks the deployed build:
#
#   1. baseUrl: Expo web must be exported with experiments.baseUrl="/play" so
#      every asset/route resolves under the subpath. We set it temporarily and
#      restore app.json afterward so native (EAS) builds are unaffected.
#
#   2. node_modules relocation: Cloudflare Pages silently DROPS any directory
#      named `node_modules` on upload. Expo nests vendored icon fonts under
#      assets/node_modules/@expo/vector-icons/... so on the deployed site those
#      .ttf files 404 (the SPA rule serves index.html instead), and every icon
#      renders as a blank box. We move them to assets/vendor and rewrite the
#      references in the JS/CSS so the fonts actually ship. (It works on a local
#      static server precisely because that server doesn't skip node_modules.)
#
#   3. noindex: the page must stay out of search engines, so we inject robots
#      meta tags (Cloudflare _headers also sets X-Robots-Tag for /play*).
#
# Usage:  ./scripts/build-play.sh        (run from the marketing repo root)
# Then:   npx wrangler pages deploy
set -euo pipefail

MARKETING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${OCTOGRAM_DIR:-$MARKETING_DIR/../octogram}"
OUT="$MARKETING_DIR/play"
TMP="$(mktemp -d)"

if [ ! -f "$APP_DIR/app.json" ]; then
  echo "error: can't find the Octogram app at $APP_DIR" >&2
  echo "       set OCTOGRAM_DIR=/path/to/octogram and retry." >&2
  exit 1
fi

cd "$APP_DIR"

# Use the Node version pinned by the app's .nvmrc when nvm is available.
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.nvm/nvm.sh"
  nvm use >/dev/null
fi

# Temporarily enable subpath hosting; always restore app.json (and clean TMP).
cp app.json app.json.bak
trap 'mv -f "$APP_DIR/app.json.bak" "$APP_DIR/app.json" 2>/dev/null || true; rm -rf "$TMP"' EXIT
node -e '
  const fs = require("fs");
  const j = JSON.parse(fs.readFileSync("app.json", "utf8"));
  j.expo.experiments = j.expo.experiments || {};
  j.expo.experiments.baseUrl = "/play";
  fs.writeFileSync("app.json", JSON.stringify(j, null, "\t") + "\n");
'

EXPO_PUBLIC_ENV=production npx expo export --platform web --output-dir "$TMP"

# Stage into ./play (drop the export manifest; Pages doesn't need it).
rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$TMP"/. "$OUT"/
rm -f "$OUT/metadata.json"

# (2) Relocate vendored assets out of any node_modules path.
if [ -d "$OUT/assets/node_modules" ]; then
  find "$OUT/_expo" -type f \( -name "*.js" -o -name "*.css" \) \
    -exec sed -i '' 's#assets/node_modules#assets/vendor#g' {} +
  mv "$OUT/assets/node_modules" "$OUT/assets/vendor"
fi

# (3) Keep the page out of search engines.
if ! grep -q 'name="robots"' "$OUT/index.html"; then
  sed -i '' 's#<title>#<meta name="robots" content="noindex, nofollow, noarchive, nosnippet, noimageindex" /><meta name="googlebot" content="noindex, nofollow, noarchive, nosnippet, noimageindex" /><title>#' "$OUT/index.html"
fi

echo "Staged web build at $OUT"
echo "Next: cd \"$MARKETING_DIR\" && npx wrangler pages deploy"
