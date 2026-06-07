# searnxg-themes

Collection de thèmes pour le métamoteur de recherche [SearXNG](https://github.com/searxng/searxng).

Chaque thème est autonome (templates Jinja + assets compilés + sources), copiable dans une
installation SearXNG et sélectionnable à côté du thème `simple` d'origine.

## Thèmes

| Thème | Description | Aperçu |
|---|---|---|
| [**google**](themes/google/) | Ressemblance forte à Google Search (clair + sombre), sans actifs déposés Google. Accueil, résultats, images, préférences. | `mockups/google/` + Docker |

## Structure du dépôt

```
searnxg-themes/
├── themes/
│   └── google/            ← le thème (voir themes/google/README.md)
│       ├── templates/     → searx/templates/google/
│       ├── static/        → searx/static/themes/google/
│       ├── src/           → sources CSS + build.sh
│       └── README.md
├── mockups/
│   └── google/            ← maquettes HTML/CSS autonomes (référence design, aperçu navigateur)
├── docs/
│   ├── google-ui-spec.md       ← spec visuelle de l'UI Google (couleurs, tailles, clair/sombre)
│   └── searxng-simple-spec.md  ← architecture du thème `simple` (templates, tokens, couplages)
├── install/
│   └── install.sh         ← installe un thème dans un checkout SearXNG
└── scripts/
    ├── docker-test.sh     ← lance SearXNG + thème via Docker (test rapide)
    └── searxng-config/    ← settings.yml de test
```

## Démarrage rapide (Docker)

```bash
./scripts/docker-test.sh up      # http://localhost:8888  (thème google activé)
./scripts/docker-test.sh down
```

## Installer dans votre SearXNG

```bash
./install/install.sh /chemin/vers/searxng
# puis dans settings.yml :  ui: { default_theme: google }
```

Voir [themes/google/README.md](themes/google/README.md) pour les détails, la personnalisation
et la reconstruction du CSS (`themes/google/build.sh`).

## Aperçu sans SearXNG (maquettes)

Les maquettes statiques servent de référence design et s'ouvrent sans backend :

```bash
cd mockups/google && python3 -m http.server 8137
# http://localhost:8137/index.html  (bascule clair/sombre en bas à droite)
```

## Ajouter un nouveau thème

1. Forkez `themes/google/` (ou les templates `simple` de SearXNG) vers `themes/<nom>/`.
2. Réécrivez les chemins internes `google/` → `<nom>/` dans les templates et le littéral
   `get_result_template('…')` de `results.html`.
3. Adaptez la couche `src/<nom>.css` (tokens + structure), puis `./build.sh`.
4. Ajoutez une ligne au tableau ci-dessus.

La découverte des thèmes par SearXNG est automatique (`os.listdir(searx/templates/)`) : un
dossier de templates + un dossier static du même nom suffisent à le rendre sélectionnable.

## Licence

AGPL-3.0-or-later (comme SearXNG).
