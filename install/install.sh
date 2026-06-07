#!/usr/bin/env bash
# =====================================================================
# Install a searnxg-themes theme into a SearXNG instance.
#
# ── Remote (no checkout needed; fetches the latest GitHub release) ────
#   # native / source install:
#   curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/install/install.sh \
#     | bash -s -- --repo OWNER/REPO --target /usr/local/searxng/searxng-src
#
#   # into a running container (quick try — lost when the container is
#   # recreated; use the docker-compose overlay for a persistent setup):
#   curl -fsSL .../install.sh | bash -s -- --repo OWNER/REPO --docker searxng
#
# ── From a local checkout (dev) ──────────────────────────────────────
#   ./install/install.sh --target /path/to/searxng [--link]
#   ./install/install.sh /path/to/searxng              # positional = --target
#
# Set the default repo once via env to skip --repo:
#   export SEARXNG_GOOGLE_REPO=OWNER/REPO
# =====================================================================
set -euo pipefail

REPO_SLUG="${SEARXNG_GOOGLE_REPO:-OWNER/REPO}"
THEME=google
TARGET=""
CONTAINER=""
REF="latest"
MODE="copy"        # copy | link
ACTION="install"   # install | uninstall

die(){ echo "error: $*" >&2; exit 1; }
usage(){
  cat <<'USAGE'
Usage:
  install.sh --target DIR            install into a SearXNG checkout/install
  install.sh --docker NAME           install into a running SearXNG container
  install.sh /path/to/searxng        (positional shorthand for --target)

Options:
  --target DIR        SearXNG dir that contains  searx/templates/simple
  --docker NAME       running SearXNG container (uses `docker cp`)
  --theme NAME        theme to install            (default: google)
  --ref TAG           release tag to fetch        (default: latest)
  --repo OWNER/REPO   release source              (or env SEARXNG_GOOGLE_REPO)
  --link              symlink instead of copy     (local checkout only)
  --uninstall         remove the theme instead of installing
  -h, --help
USAGE
  exit "${1:-0}"
}

# ---- parse args (a leading non-flag arg is treated as --target) ----
[ $# -gt 0 ] || usage 1
if [ "${1#-}" = "$1" ] && [ -n "${1:-}" ]; then TARGET="$1"; shift; fi
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2;;
    --docker) CONTAINER="${2:-}"; shift 2;;
    --theme)  THEME="${2:-}"; shift 2;;
    --ref)    REF="${2:-}"; shift 2;;
    --repo)   REPO_SLUG="${2:-}"; shift 2;;
    --link)   MODE="link"; shift;;
    --uninstall) ACTION="uninstall"; shift;;
    -h|--help) usage 0;;
    *) die "unknown option: $1 (see --help)";;
  esac
done
[ -n "$TARGET" ] || [ -n "$CONTAINER" ] || die "need --target DIR or --docker NAME (see --help)"

# ---- locate the theme source (local checkout, else download release) ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo /nonexistent)"
SRC=""        # a dir containing templates/ and static/
TMP=""
cleanup(){ [ -n "$TMP" ] && rm -rf "$TMP" || true; }
trap cleanup EXIT

find_local(){
  for c in "$SCRIPT_DIR/../themes/$THEME" "$SCRIPT_DIR/themes/$THEME" "$SCRIPT_DIR"; do
    if [ -d "$c/templates" ] && [ -d "$c/static" ]; then SRC="$(cd "$c" && pwd)"; return 0; fi
  done
  return 1
}
download(){
  command -v curl  >/dev/null 2>&1 || die "curl is required to download the theme"
  command -v unzip >/dev/null 2>&1 || die "unzip is required to extract the theme"
  [ "$REPO_SLUG" != "OWNER/REPO" ] || die "set --repo OWNER/REPO (or env SEARXNG_GOOGLE_REPO)"
  local b="https://github.com/$REPO_SLUG/releases" url
  if [ "$REF" = latest ]; then url="$b/latest/download/searxng-$THEME-theme.zip"
  else url="$b/download/$REF/searxng-$THEME-theme.zip"; fi
  TMP="$(mktemp -d)"
  echo "↓ downloading $url"
  curl -fSL "$url" -o "$TMP/theme.zip" || die "download failed: $url"
  unzip -q "$TMP/theme.zip" -d "$TMP"
  SRC="$TMP/searxng-$THEME"
  [ -d "$SRC/templates" ] || die "unexpected archive layout in $url"
}

if find_local; then echo "• using local theme source: $SRC"
elif [ "$MODE" = link ]; then die "--link requires a local checkout (none found next to this script)"
else download; fi

# ---- install / uninstall ----
install_native(){
  local d="$TARGET"
  [ -d "$d/searx/templates/simple" ] || die "'$d' doesn't look like SearXNG (no searx/templates/simple)"
  local tpl="$d/searx/templates/$THEME" st="$d/searx/static/themes/$THEME"
  rm -rf "$tpl" "$st"
  if [ "$ACTION" = uninstall ]; then echo "✓ removed '$THEME' from $d"; return; fi
  if [ "$MODE" = link ]; then
    ln -s "$SRC/templates" "$tpl"; ln -s "$SRC/static" "$st"
    echo "✓ symlinked '$THEME' into $d"
  else
    cp -R "$SRC/templates" "$tpl"; cp -R "$SRC/static" "$st"
    echo "✓ installed '$THEME' into $d"
  fi
}
install_docker(){
  command -v docker >/dev/null 2>&1 || die "docker not found"
  docker inspect "$CONTAINER" >/dev/null 2>&1 || die "no such container: $CONTAINER"
  local base="/usr/local/searxng/searx"
  docker exec "$CONTAINER" rm -rf "$base/templates/$THEME" "$base/static/themes/$THEME" 2>/dev/null || true
  if [ "$ACTION" = uninstall ]; then echo "✓ removed '$THEME' from container $CONTAINER (restart to apply)"; return; fi
  docker cp "$SRC/templates" "$CONTAINER:$base/templates/$THEME"
  docker cp "$SRC/static"    "$CONTAINER:$base/static/themes/$THEME"
  echo "✓ copied '$THEME' into container $CONTAINER"
  echo "  → SearXNG discovers themes at startup, so restart now:  docker restart $CONTAINER"
  echo "  ⚠ docker cp is NOT persistent — changes vanish when the container is recreated."
  echo "    For a permanent Docker setup use the compose overlay (see docker/ in the repo)."
}

[ -n "$TARGET" ]    && install_native
[ -n "$CONTAINER" ] && install_docker

if [ "$ACTION" = install ]; then
cat <<EOF

Next:
  1. set   ui.default_theme: $THEME   in your settings.yml
     (or keep "simple" as default and pick "$THEME" per-user in
      Preferences → user interface → theme)
  2. restart SearXNG
EOF
fi
