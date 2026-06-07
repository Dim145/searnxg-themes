# Thème `google` pour SearXNG

Un thème SearXNG qui reproduit fortement l'interface de **Google Search** (2024–2026),
en **clair et sombre**, sans réutiliser les actifs déposés de Google (logo, Product Sans,
glyphes d'icônes). Marque maison : wordmark multicolore « SearXNG », corps en **Arial**
(le rendu réel de Google), icônes SVG inline.

Pages couvertes : **accueil**, **résultats web**, **images** (grille dense justifiée),
**préférences**, et — par héritage du thème `simple` — toutes les autres pages
(vidéos, actualités, cartes, statistiques, 404…), recolorées à la palette Google.

![pages](../../docs/) <!-- captures dans docs/ si ajoutées -->

## Comment c'est construit

Le thème **forke les templates Jinja de `simple`** (DOM identique → couverture complète
de tous les types de résultats) puis applique une **couche d'override CSS Google**
par-dessus le CSS compilé de `simple`.

```
themes/google/
├── templates/      → copié dans  searx/templates/google/      (Jinja forké de simple)
├── static/         → copié dans  searx/static/themes/google/   (sortie : css + js + img)
│   ├── sxng-ltr.min.css   (= base simple + src/google.css)   ← généré par build.sh
│   ├── sxng-rtl.min.css
│   ├── sxng-core.min.js   (réutilisé de simple : comportement identique)
│   ├── google-lightbox.js (maison : clic-fond ferme le visualiseur + spinner hi-res)
│   └── img/ …             (favicons, icônes, etc. de simple)
├── src/
│   ├── google.css   ← LA source à éditer (tokens Google + pont --color-* + structure)
│   ├── base-ltr.css ← CSS compilé de `simple` (vendoré, ne pas éditer)
│   └── base-rtl.css
└── build.sh         ← régénère static/sxng-*.min.css = base + google.css
```

Le pont remappe les variables `--color-*` de `simple` vers une palette Google via des
tokens `--g-*` : **toute** l'UI est recolorée (clair / sombre / black / auto) automatiquement,
puis les surfaces principales (barre de recherche, onglets, résultats, sidebar, accueil,
préférences) sont **remises en forme** pour coller à Google.

> Choix volontaire : on n'a **pas** forké la toolchain Vite+Less de SearXNG. Une couche CSS
> concaténée donne le même résultat avec beaucoup moins de pièces mobiles. Pour régénérer :
> `./build.sh`.

## Installation

Pour **installer sur une instance** (one-liner `curl … | bash`, overlay
`docker-compose` persistant, ou ZIP de release), voir *Installer dans votre SearXNG*
dans le [README racine](../../README.md). Ci-dessous : l'installation **depuis ce dépôt** (dev).

### Depuis un checkout local

```bash
# copie dans une install SearXNG (dossier contenant searx/templates/simple)
./install/install.sh --target /chemin/vers/searxng
# lien symbolique (édition à chaud pendant le dev)
./install/install.sh --target /chemin/vers/searxng --link
# désinstaller
./install/install.sh --target /chemin/vers/searxng --uninstall
```

Ou manuellement :

```bash
cp -r themes/google/templates  /chemin/vers/searxng/searx/templates/google
cp -r themes/google/static      /chemin/vers/searxng/searx/static/themes/google
```

Puis dans `settings.yml` :

```yaml
ui:
  default_theme: google
```

…ou laissez `simple` par défaut et choisissez **Google** par utilisateur dans
*Préférences → interface utilisateur → thème*. Redémarrez SearXNG.

> Gardez le thème `simple` installé (SearXNG le fournit toujours) : `google` réutilise
> quelques assets partagés en repli.

### Test rapide en Docker

```bash
./scripts/docker-test.sh up      # http://localhost:8888
./scripts/docker-test.sh down
```

Monte le thème dans l'image officielle `searxng/searxng` (aucune reconstruction d'image).

### Construire le ZIP de release

```bash
./install/package.sh google      # → dist/searxng-google-theme.zip (+ .sha256)
```

## Personnalisation

- **Couleurs** : éditez les tokens `--g-*` en haut de `src/google.css`, puis `./build.sh`.
- **Bleu des titres** : `--g-link` (`#1a0dab` par défaut ; `#1558d6` pour un bleu plus vif).
- **Wordmark** : couleurs par lettre dans `.wordmark .c1…`; le markup est dans
  `templates/index.html`, `templates/search.html`, `templates/page_with_header.html`.
  Police : **Poppins auto-hébergée** (`static/fonts/poppins-{600,700}.woff2`, sous-ensemble
  latin) — *jamais chargée depuis fonts.google.com* (vie privée). Pour changer, remplacez
  les woff2 et le `@font-face` en tête de `src/google.css`.
- **Corps & titres** : Arial (le rendu réel de Google) via `--g-font-body` / `--g-font-display`.

## Compatibilité

Forké depuis SearXNG (templates `simple` identiques à l'image `searxng/searxng:latest`,
vérifié au byte près). Si une future version de SearXNG modifie les templates `simple`,
re-synchronisez `templates/` et `src/base-*.css` puis relancez `./build.sh`.

## Licence

AGPL-3.0-or-later (comme SearXNG).
