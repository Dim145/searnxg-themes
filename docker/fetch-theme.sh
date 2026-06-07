#!/usr/bin/env bash
# =====================================================================
# Download a released theme into ./searxng-<theme>/ for the bind-mount in
# docker-compose.override.yml, verifying the checksum. Then:
#   docker compose up -d
#
#   ./fetch-theme.sh [theme] [ref]
#       theme   default: google
#       ref     default: latest   (or a release tag)
#   Fork? override the source: SEARXNG_GOOGLE_REPO=OWNER/REPO ./fetch-theme.sh
# =====================================================================
set -euo pipefail
REPO_SLUG="${SEARXNG_GOOGLE_REPO:-Dim145/searnxg-themes}"
THEME="${1:-google}"
REF="${2:-latest}"

[ "$REPO_SLUG" != "OWNER/REPO" ] || {
  echo "set SEARXNG_GOOGLE_REPO=OWNER/REPO (or edit this script)" >&2; exit 1; }
command -v curl  >/dev/null 2>&1 || { echo "curl required" >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip required" >&2; exit 1; }

base="https://github.com/$REPO_SLUG/releases"
if [ "$REF" = latest ]; then url="$base/latest/download/searxng-$THEME-theme.zip"
else url="$base/download/$REF/searxng-$THEME-theme.zip"; fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
echo "↓ $url"
curl -fSL "$url" -o "$tmp/theme.zip" || { echo "download failed" >&2; exit 1; }

# verify checksum if published alongside the archive
if curl -fsSL "$url.sha256" -o "$tmp/theme.sha256" 2>/dev/null; then
  expected="$(cut -d' ' -f1 < "$tmp/theme.sha256")"
  if command -v sha256sum >/dev/null 2>&1; then got="$(sha256sum "$tmp/theme.zip" | cut -d' ' -f1)"
  else got="$(shasum -a 256 "$tmp/theme.zip" | cut -d' ' -f1)"; fi
  [ "$expected" = "$got" ] && echo "✓ checksum OK" || { echo "✗ checksum mismatch" >&2; exit 1; }
fi

unzip -q -o "$tmp/theme.zip" -d "$tmp"
rm -rf "./searxng-$THEME"
mv "$tmp/searxng-$THEME" "./searxng-$THEME"
echo "✓ theme extracted to ./searxng-$THEME"
echo "  next: ensure ui.default_theme: $THEME in your settings.yml, then 'docker compose up -d'"
