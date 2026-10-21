#!/bin/bash
# Regenerates public/downloads/postgresql-14-upgrade-checklist.pdf from the built page.
# Needs `npm run build` first and `npx astro preview` running on PREVIEW (default http://localhost:4321).
# Links are rewritten to the production domain so the PDF does not point at localhost.
set -euo pipefail
cd "$(dirname "$0")/.."
PREVIEW="${PREVIEW:-http://localhost:4321}"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
TMP=dist/print-checklist

mkdir -p "$TMP" public/downloads
sed -E 's#(<a [^>]*href=")/#\1https://databasedeveloper.dev/#g' dist/postgresql-14-upgrade-checklist/index.html > "$TMP/index.html"
trap 'rm -rf "$TMP"' EXIT
"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
  --print-to-pdf=public/downloads/postgresql-14-upgrade-checklist.pdf "$PREVIEW/print-checklist" 2>/dev/null
echo "Wrote public/downloads/postgresql-14-upgrade-checklist.pdf"
