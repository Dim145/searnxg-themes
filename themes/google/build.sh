#!/usr/bin/env bash
# =====================================================================
# Build the "google" theme stylesheets.
#
# The google theme deliberately avoids forking SearXNG's heavy Vite+Less
# toolchain. Instead it layers a hand-authored Google override
# (src/google.css) on top of simple's already-compiled base CSS
# (src/base-ltr.css / src/base-rtl.css, vendored from upstream simple).
# That gives full element coverage (everything simple styles) recoloured
# to Google, plus the reshaped main surfaces — with far fewer moving parts.
#
# Output lands in static/ with the exact filenames base.html links.
# =====================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

banner="/* Built by build.sh — simple base CSS + Google override layer (src/google.css). Do not edit by hand; edit src/google.css. */"

build_one() {
  local base="$1" out="$2"
  { echo "$banner"; cat "$HERE/src/$base"; echo; cat "$HERE/src/google.css"; } > "$HERE/static/$out"
  echo "  built static/$out  ($(wc -c < "$HERE/static/$out" | tr -d ' ') bytes)"
}

echo "Building google theme CSS:"
build_one base-ltr.css sxng-ltr.min.css
build_one base-rtl.css sxng-rtl.min.css
echo "Done."
