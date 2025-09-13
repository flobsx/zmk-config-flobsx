# ZMK Config Corne Optimot Custom

Cette configuration ZMK est optimisée pour un clavier Corne avec disposition Optimot et intègre des scripts de build automatisés.

## 🚀 Construction rapide des firmwares

### Configuration initiale

```bash
# Configuration complète (recommandé pour la première utilisation)
brew install west ninja
pip install pyelftools
make setup

# Ou installation des dépendances seulement
make install
```

### Construction des firmwares

```bash
# Construction simple
make build

# Construction avec nettoyage préalable
make clean

# Afficher l'aide
make help
```

### Commandes utiles

```bash
# Lister les firmwares générés
make firmware

# Vérifier la configuration
make check

# Tester sans construire
make test

# Nettoyer complètement
make clean-all
```

Les firmwares générés seront disponibles dans le dossier `./firmware/`.

## 📁 Structure du projet

```
├── Makefile               # Fichier de build principal
├── build.yaml            # Configuration de build
├── scripts/
│   ├── build.sh          # Script de construction des firmwares
│   └── install-deps.sh   # Script d'installation des dépendances
├── config/
│   ├── corne.conf        # Configuration du clavier
│   ├── corne.keymap      # Disposition des touches
│   └── west.yml          # Configuration des modules
├── firmware/             # Firmwares générés (.uf2)
└── BUILD.md             # Documentation détaillée du build
```

## ⌨️ Disposition clavier

Cette configuration utilise une disposition Optimot personnalisée pour clavier français.

### keyboard-layout-editor

| Description | Link |
|---|---|
| Main Layer | <https://keyboard-layout-editor.com/##@@_x:3&a:5&fa@:0&:0&:0&:0&:0&:0&:5%3B%3B&=%0A%C5%93%0A%0A%0A%0A%0Ao&_x:7&a:7&fa@:5%3B%3B&=l%3B&@_y:-0.75&x:2%3B&=j&_x:1%3B&=b&_x:5%3B&=d&_x:1%3B&=%E2%98%85%3B&@_y:-0.75&fa@:9%3B%3B&=%E2%90%9B&_fa@:5%3B%3B&=z&_x:3%3B&=%3F&_x:3%3B&=f&_x:3%3B&=x&=%3B&@_y:-0.5&x:3%3B&=e&_x:7%3B&=s%3B&@_y:-0.75&x:2%3B&=i&_x:1%3B&=u&_x:5%3B&=t&_x:1%3B&=r%3B&@_y:-0.75&fa@:9%3B%3B&=%E2%86%B9&_fa@:5%3B%3B&=a&_x:3&a:5&fa@:0&:0&:0&:0&:0&:0&:5%3B%3B&=%2F%3B%0A%0A%0A%0A%0A%0A,&_x:3&a:7&fa@:5%3B%3B&=p&_x:3%3B&=n&=%3B&@_y:-0.5&x:3%3B&=q&_x:7%3B&=m%3B&@_y:-0.75&x:2%3B&=y&_x:1&a:5&fa@:0&:0&:0&:0&:0&:0&:5%3B%3B&=%2F:%0A%0A%0A%0A%0A%0A.&_x:5&a:7&fa@:5%3B%3B&=c&_x:1%3B&=h%3B&@_y:-0.75&fa@:9%3B%3B&=%E2%87%A7&_fa@:5%3B%3B&=k&_x:3%3B&=w&_x:3%3B&=g&_x:3%3B&=v&_fa@:9%3B%3B&=%E2%87%A7%3B&@_y:-0.04999999999999982&x:3.5&fa@:5%3B%3B&=%E2%9C%B4%EF%B8%8F&_x:6%3B&=%3B&@_r:15&rx:4.75&ry:3.75&y:-0.2999999999999998%3B&=%E2%8C%AB%3B&@_r:25&rx:5.75&y:-0.5499999999999998&x:0.25&fa@:9%3B&h:1.5%3B&=%E2%90%A3%3B&@_r:-25&rx:9.5&y:-0.6499999999999999&x:-1.4499999999999993&h:1.5%3B&=%E2%86%A9%3B&@_r:-15&rx:10.5&y:-0.3500000000000001&x:-1.25&fa@:5%3B%3B&=%E2%8C%A6> |

## 🔧 Configuration matérielle

- **Microcontrôleur** : Nice!Nano v2
- **Écrans** : Nice!View avec adaptateur
- **Shields** : nice_futurama_sus (custom)

## 📚 Documentation

Pour plus de détails sur la configuration et le processus de build, consultez [BUILD.md](BUILD.md).

## 🔗 Ressources

- [Documentation ZMK](https://zmk.dev/)
- [Disposition Optimot](https://optimot.fr/)
- [Nice!Nano](https://nicekeyboards.com/nice-nano/)

## 📝 Licence

Cette configuration est basée sur ZMK et suit la même licence MIT.
