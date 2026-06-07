# Docker install (persistent, official image)

For a [searxng-docker](https://github.com/searxng/searxng-docker) setup, install the
theme **without rebuilding any image** — bind-mount it into the official
`searxng/searxng` container via a compose override.

> Replace `OWNER/REPO` with this repository's slug (e.g. `ddubois/searnxg-themes`).

```bash
# in your searxng-docker directory (next to docker-compose.yml):
curl -fsSLO https://raw.githubusercontent.com/OWNER/REPO/main/docker/docker-compose.override.yml
curl -fsSLO https://raw.githubusercontent.com/OWNER/REPO/main/docker/fetch-theme.sh
chmod +x fetch-theme.sh

# download the theme into ./searxng-google/
SEARXNG_GOOGLE_REPO=OWNER/REPO ./fetch-theme.sh

# enable it, then start
#   searxng/settings.yml:
#     ui:
#       default_theme: google
docker compose up -d
```

What the override does:

```yaml
services:
  searxng:                       # ← must match the service name in YOUR compose
    volumes:
      - ./searxng-google/templates:/usr/local/searxng/searx/templates/google:ro
      - ./searxng-google/static:/usr/local/searxng/searx/static/themes/google:ro
```

`volumes:` is **merged additively** with your existing compose, so your
`settings.yml` / valkey mounts are kept. `:ro` mounts the theme read-only.

**Update later:**

```bash
SEARXNG_GOOGLE_REPO=OWNER/REPO ./fetch-theme.sh   # re-download
docker compose restart searxng
```

**Keep `simple` enabled** — SearXNG always ships it and `google` reuses a few of
its shared assets. Users can pick *Google* per-user in **Preferences → user
interface → theme** even if it isn't the default.

> Compatibility: the theme forks SearXNG's `simple` templates, so it's tied to a
> SearXNG version. Each release notes the version it was tested against; if you
> run a much newer SearXNG and a page looks off, grab a newer theme release.
