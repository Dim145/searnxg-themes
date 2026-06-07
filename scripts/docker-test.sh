#!/usr/bin/env bash
# =====================================================================
# Spin up a local SearXNG (official image) with the "google" theme
# mounted in, for visual testing. No image rebuild needed: the theme is
# two bind-mounted dirs + a settings.yml that sets ui.default_theme.
#
#   ./scripts/docker-test.sh up      # start (http://localhost:8888)
#   ./scripts/docker-test.sh down     # stop & remove
#   ./scripts/docker-test.sh logs     # follow logs
# =====================================================================
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
NAME=searxng-google
PORT=8888
IMAGE=searxng/searxng:latest

cmd="${1:-up}"
case "$cmd" in
  up)
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    docker run --rm -d --name "$NAME" -p "$PORT:8080" \
      -v "$REPO/scripts/searxng-config:/etc/searxng" \
      -v "$REPO/themes/google/templates:/usr/local/searxng/searx/templates/google:ro" \
      -v "$REPO/themes/google/static:/usr/local/searxng/searx/static/themes/google:ro" \
      -e "SEARXNG_BASE_URL=http://localhost:$PORT/" \
      "$IMAGE" >/dev/null
    echo "SearXNG + google theme starting at http://localhost:$PORT/"
    echo "  (give it ~5-10s, then: $0 logs  /  open the URL)"
    ;;
  down)
    docker rm -f "$NAME" >/dev/null 2>&1 && echo "stopped $NAME" || echo "not running"
    ;;
  logs)
    docker logs -f "$NAME"
    ;;
  *)
    echo "usage: $0 {up|down|logs}"; exit 1;;
esac
