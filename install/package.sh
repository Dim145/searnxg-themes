#!/usr/bin/env bash
# =====================================================================
# Build a ready-to-deploy release archive for a theme.
#
#   ./install/package.sh [theme] [outdir]
#       theme    default: google
#       outdir   default: <repo>/dist
#
# Produces:  <outdir>/searxng-<theme>-theme.zip   (+ .sha256)
#
# Archive layout (single top dir, drop-in friendly):
#   searxng-<theme>/
#     ├── templates/   → install into  searx/templates/<theme>
#     ├── static/      → install into  searx/static/themes/<theme>
#     ├── install.sh   (self-contained installer)
#     ├── VERSION
#     ├── LICENSE
#     └── README.txt
#
# Used by the GitHub release workflow and runnable locally.
# =====================================================================
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
THEME="${1:-google}"
OUTDIR="${2:-$REPO/dist}"
SRC="$REPO/themes/$THEME"

[ -d "$SRC/templates" ] || { echo "error: no theme '$THEME' at $SRC" >&2; exit 1; }

# Always rebuild the CSS so the archive can never ship stale output.
if [ -x "$SRC/build.sh" ]; then ( cd "$SRC" && ./build.sh ); fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
PKG="$STAGE/searxng-$THEME"
mkdir -p "$PKG"
cp -R "$SRC/templates" "$PKG/templates"
cp -R "$SRC/static"    "$PKG/static"
# drop dev-only source maps — they bloat the archive (several MB) and the theme
# works without them (browsers just skip the missing sourcemap).
find "$PKG/static" -name '*.map' -delete
cp "$REPO/install/install.sh" "$PKG/install.sh"
[ -f "$REPO/LICENSE" ] && cp "$REPO/LICENSE" "$PKG/LICENSE"

VER="${GITHUB_REF_NAME:-$(git -C "$REPO" describe --tags --always 2>/dev/null || echo dev)}"
TESTED="$(cat "$SRC/.searxng-version" 2>/dev/null || echo 'recent — see README')"
cat > "$PKG/VERSION" <<EOF
theme:               $THEME
version:             $VER
built:               $(date -u +%Y-%m-%dT%H:%M:%SZ)
tested-with-searxng: $TESTED
EOF

cat > "$PKG/README.txt" <<EOF
SearXNG "$THEME" theme — $VER
================================================================

Install (pick one):

  A) into a running container (quick try; NOT persistent across
     container recreation — use the docker-compose overlay instead
     for a permanent Docker setup):
       ./install.sh --docker <container-name>

  B) native / source install (a dir that contains searx/templates/simple):
       ./install.sh --target /path/to/searxng

  C) manual copy:
       cp -r templates  <searxng>/searx/templates/$THEME
       cp -r static     <searxng>/searx/static/themes/$THEME

Then set   ui.default_theme: $THEME   in settings.yml (or pick "$THEME"
per-user in Preferences -> user interface -> theme) and restart SearXNG.

Keep the bundled "simple" theme installed; "$THEME" reuses a few of its
shared assets.

License: AGPL-3.0-or-later (see LICENSE). Derived from SearXNG's "simple" theme.
EOF

mkdir -p "$OUTDIR"
ZIP="$OUTDIR/searxng-$THEME-theme.zip"
rm -f "$ZIP" "$ZIP.sha256"
( cd "$STAGE" && zip -rqX "$ZIP" "searxng-$THEME" )
if command -v sha256sum >/dev/null 2>&1; then
  ( cd "$OUTDIR" && sha256sum "$(basename "$ZIP")" > "$ZIP.sha256" )
else
  ( cd "$OUTDIR" && shasum -a 256 "$(basename "$ZIP")" > "$ZIP.sha256" )
fi
echo "packaged: $ZIP"
echo "sha256:   $(cut -d' ' -f1 < "$ZIP.sha256")"
