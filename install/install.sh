#!/usr/bin/env bash
# =====================================================================
# Install the "google" theme into a SearXNG checkout / installation.
#
# Usage:
#   ./install/install.sh /path/to/searxng        # copy
#   ./install/install.sh /path/to/searxng --link  # symlink (dev: live edits)
#
# It places:
#   themes/google/templates -> <searxng>/searx/templates/google
#   themes/google/static     -> <searxng>/searx/static/themes/google
# Then enable it in your settings.yml:
#   ui:
#     default_theme: google
# (or pick "Google" per-user in Preferences → user interface → theme).
#
# NOTE: keep the bundled "simple" theme installed — SearXNG always ships
# it and the google theme falls back to a couple of its shared assets.
# =====================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$HERE/themes/google"

DEST="${1:-}"
MODE="${2:-copy}"
if [[ -z "$DEST" ]]; then
  echo "usage: $0 /path/to/searxng [--link]"; exit 1
fi
if [[ ! -d "$DEST/searx/templates/simple" ]]; then
  echo "error: '$DEST' does not look like a SearXNG checkout (no searx/templates/simple)"; exit 1
fi

TPL_DEST="$DEST/searx/templates/google"
STATIC_DEST="$DEST/searx/static/themes/google"

if [[ "$MODE" == "--link" ]]; then
  rm -rf "$TPL_DEST" "$STATIC_DEST"
  ln -s "$SRC/templates" "$TPL_DEST"
  ln -s "$SRC/static" "$STATIC_DEST"
  echo "symlinked google theme into $DEST"
else
  rm -rf "$TPL_DEST" "$STATIC_DEST"
  cp -r "$SRC/templates" "$TPL_DEST"
  cp -r "$SRC/static" "$STATIC_DEST"
  echo "copied google theme into $DEST"
fi

echo
echo "Next:"
echo "  1. set  ui.default_theme: google  in your settings.yml (or choose it in Preferences)"
echo "  2. restart SearXNG"
