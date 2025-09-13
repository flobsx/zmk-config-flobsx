# Scripts ZMK

Ce dossier contient les scripts de build et d'installation pour le projet ZMK.

## Scripts disponibles

### `build.sh`

Script principal de construction des firmwares ZMK. Il :

- Lit la configuration depuis `build.yaml`
- Initialise l'environnement West
- Construit les firmwares pour chaque configuration
- Copie les fichiers `.uf2` dans `./firmware/`

**Usage direct :**

```bash
./scripts/build.sh [--clean] [--help]
```

**Usage recommandé (via Makefile) :**

```bash
make build
make clean
```

### `install-deps.sh`

Script d'installation des dépendances nécessaires pour ZMK :

- Dépendances système (cmake, ninja, etc.)
- West (outil de build Zephyr/ZMK)
- yq (parser YAML)
- Zephyr SDK (optionnel)

**Usage direct :**

```bash
./scripts/install-deps.sh [--west-only] [--yq-only]
```

**Usage recommandé (via Makefile) :**

```bash
make setup    # Installation complète
make install  # Installation des dépendances
make deps     # West + yq seulement
```

## Intégration avec Makefile

Ces scripts sont intégrés dans le Makefile racine pour une utilisation simplifiée.
Utilisez `make help` pour voir toutes les commandes disponibles.

## Structure

```
scripts/
├── README.md          # Ce fichier
├── build.sh           # Script de construction
└── install-deps.sh    # Script d'installation
```
