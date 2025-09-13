# Build System pour ZMK

Ce projet utilise un Makefile pour automatiser la construction des firmwares ZMK et gérer les dépendances.

## 🚀 Démarrage rapide

### Configuration initiale (première utilisation)

```bash
make setup
```

Cette commande installe toutes les dépendances et vérifie la configuration.

### Construction des firmwares

```bash
# Construction simple
make build

# Construction avec nettoyage préalable
make clean
```

## 📋 Commandes disponibles

### Construction

```bash
make build        # Construire les firmwares
make clean        # Construire avec nettoyage préalable
make clean-all    # Supprimer tous les fichiers générés
```

### Configuration et dépendances

```bash
make setup        # Configuration initiale complète
make install      # Installer toutes les dépendances
make deps         # Installer seulement West et yq
make check        # Vérifier la configuration
make test         # Tester sans construire
```

### Utilitaires

```bash
make firmware     # Lister les firmwares générés
make help         # Afficher l'aide complète
```

## 🔧 Prérequis

Les dépendances suivantes sont installées automatiquement avec `make setup` :

1. **West** (outil de build de Zephyr/ZMK)
2. **yq** (parser YAML, optionnel)
3. **Dépendances système** (cmake, ninja, etc.)
4. **Zephyr SDK** (optionnel, installation guidée)

## Fonctionnement

Le script :

1. **Lit la configuration** depuis `build.yaml`
2. **Initialise l'environnement West** si nécessaire
3. **Met à jour les modules** ZMK et dépendances
4. **Construit chaque firmware** défini dans la configuration
5. **Copie les fichiers .uf2** dans le dossier `./firmware`
6. **Génère des noms de fichiers** descriptifs basés sur la board et le shield

## Structure des fichiers générés

Les firmwares générés suivent cette nomenclature :

```
[shield]-[board]-zmk.uf2
```

Par exemple :

- `corne_left-nice_view_adapter-nice_futurama_sus-nice_nano_v2-zmk.uf2`
- `corne_right-nice_view_adapter-nice_futurama_sus-nice_nano_v2-zmk.uf2`

## Configuration

Le script utilise le fichier `build.yaml` pour déterminer quels firmwares construire. Voici un exemple de configuration :

```yaml
include:
  - board: nice_nano_v2
    shield: corne_left nice_view_adapter nice_futurama_sus
    snippet: studio-rpc-usb-uart
  - board: nice_nano_v2
    shield: corne_right nice_view_adapter nice_futurama_sus
```

## Dépannage

### Erreur "west command not found"

Installez West avec pip :

```bash
pip3 install west
```

### Erreur "toolchain not found"

Assurez-vous d'avoir installé le Zephyr SDK ou ARM GCC toolchain et que les variables d'environnement sont correctement définies.

### Erreur "build.yaml not found"

Exécutez le script depuis la racine de votre projet ZMK où se trouve le fichier `build.yaml`.

### Problèmes de parsing YAML

Si le script a des difficultés à parser `build.yaml`, installez `yq` pour une analyse plus robuste du fichier YAML.

## Personnalisation

Vous pouvez modifier les variables au début du script pour personnaliser :

- `CONFIG_DIR` : Répertoire de configuration (par défaut : "config")
- `FIRMWARE_DIR` : Répertoire de sortie des firmwares (par défaut : "firmware")
- `BUILD_DIR` : Répertoire de build temporaire (par défaut : "build")

## Licence

Ce script est fourni sous la même licence que votre configuration ZMK.
