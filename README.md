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
│   ├── install.sh         ← installe un thème (local OU télécharge la release ; --target/--docker)
│   └── package.sh         ← construit le ZIP de release (dist/searxng-<thème>-theme.zip)
├── docker/
│   ├── docker-compose.override.yml  ← overlay bind-mount pour searxng-docker (persistant)
│   ├── fetch-theme.sh     ← télécharge la release dans ./searxng-google/
│   └── README.md
├── .github/workflows/
│   ├── release.yml        ← tag → build ZIP + crée la Release GitHub
│   └── ci.yml             ← push/PR → build + smoke-test (boot SearXNG, rendu OK)
├── scripts/
│   ├── docker-test.sh     ← lance SearXNG + thème via Docker (test rapide)
│   └── searxng-config/    ← settings.yml de test
├── LICENSE                ← AGPL-3.0-or-later
└── NOTICE                 ← attribution SearXNG + marques
```

## Démarrage rapide (Docker)

```bash
./scripts/docker-test.sh up      # http://localhost:8888  (thème google activé)
./scripts/docker-test.sh down
```

## Installer dans votre SearXNG

> Dépôt : **`Dim145/searnxg-themes`** (déjà câblé dans les scripts). Les commandes
> récupèrent la dernière *release* : un ZIP prêt à déposer, construit par la CI.

**Docker (searxng-docker) — persistant, image officielle conservée** *(recommandé)*

Dans le dossier de votre `docker-compose.yml` :

```bash
curl -fsSLO https://raw.githubusercontent.com/Dim145/searnxg-themes/main/docker/docker-compose.override.yml
curl -fsSLO https://raw.githubusercontent.com/Dim145/searnxg-themes/main/docker/fetch-theme.sh && chmod +x fetch-theme.sh
./fetch-theme.sh                                       # → ./searxng-google/
#   settings.yml :  ui: { default_theme: google }
docker compose up -d
```

Détails et mise à jour : [docker/README.md](docker/README.md).

**Installation native / source — une commande**

```bash
curl -fsSL https://raw.githubusercontent.com/Dim145/searnxg-themes/main/install/install.sh \
  | bash -s -- --target /usr/local/searxng/searxng-src
# essai rapide dans un conteneur lancé (non persistant) :
#   … | bash -s -- --docker searxng   (puis `docker restart searxng`)
```

**Manuel (ZIP de release)** — téléchargez `searxng-google-theme.zip` depuis *Releases* :

```bash
unzip searxng-google-theme.zip
cp -r searxng-google/templates  /chemin/searxng/searx/templates/google
cp -r searxng-google/static     /chemin/searxng/searx/static/themes/google
```

Dans tous les cas : `ui.default_theme: google` dans `settings.yml` (ou choisi par
utilisateur dans *Préférences → interface → thème*), puis redémarrez SearXNG. Gardez
le thème `simple` installé. Voir [themes/google/README.md](themes/google/README.md) pour
les détails et la reconstruction du CSS.

> **Compatibilité** : le thème forke les templates `simple`, il est donc lié à une
> version de SearXNG. Chaque release indique la version testée ; sur un SearXNG bien
> plus récent, prenez une release plus récente (ou ouvrez une issue).

## Publier une release (mainteneur)

Le slug `Dim145/searnxg-themes` est déjà câblé partout (scripts + docs ; les workflows
utilisent `github.repository`). Pour un **fork**, remplace-le ou passe `--repo OWNER/REPO`.

1. **Taguez** pour déclencher la CI de release (build du ZIP + création de la *Release*) :
   ```bash
   git tag google-v2026.06.07 && git push origin google-v2026.06.07
   ```
2. Le workflow `ci.yml` valide chaque push : build du ZIP, démarrage de SearXNG avec le
   thème monté, et vérification que les pages rendent sans erreur de template.

Construire le ZIP localement : `./install/package.sh google` → `dist/searxng-google-theme.zip`.

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
